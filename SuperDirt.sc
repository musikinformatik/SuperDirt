/*

SuperCollider implementation of Dirt


Open Qustions:

* should accelerate reduce the playback time? (currently: yes)
* should samples reverse when accelerate is negative and large? (currently: no)
* is accelerate direction relative to rate or absolute? (currently: absolute)

TODO:
* let's make a nice protocol of how to extend it better

One first step would be: Tidal sends pairs of argument names and values
If tidal sends only those that matter (omitting the defaults) this would be more efficient
Then we could map arguments to effects, and new effects could be added easily

*/

SuperDirt {

	var <numChannels, <server;
	var <buffers, <vowels;
	var <>dirtBusses;

	classvar <>maxSampleNumChannels = 2;

	*new { |numChannels = 2, server|
		^super.newCopyArgs(numChannels, server ? Server.default).init
	}

	init {
		buffers = ();
		this.loadSynthDefs;
		this.initVowels(\counterTenor);
	}

	start { |ports = 57120, outBusses = 0, senderAddrs = (NetAddr("127.0.0.1"))|
		dirtBusses = [ports, outBusses, senderAddrs].flop.collect(DirtBus(this, *_))
	}

	stop {
		dirtBusses.do(_.free);
	}

	free {
		this.freeSoundFiles;
		this.stop;
	}

	getBuffer { |name|
		var key, index, allbufs;
		#key, index = name.asString.split($:);
		key = key.asSymbol;
		allbufs = buffers[key];
		if(allbufs.isNil) { ^nil };
		index = (index ? 0).asInteger;
		^allbufs[index]
	}

	loadSoundFiles { |path, fileExtension = "wav", delay = 0.001|
		var folderPaths;
		if(server.serverRunning.not) {
			"Superdirt: server not running - cannot load sound files.".warn; ^this
		};
		path = path ?? { "samples".resolveRelative };
		folderPaths = pathMatch(path +/+ "**");
		"\nloading sample banks:\n".post;
		{
			folderPaths.do { |folderPath|
				PathName(folderPath).filesDo { |filepath|
					var buf, name;
					if(filepath.extension.find(fileExtension, true).notNil) {
						buf = Buffer.read(server, filepath.fullPath);
						name = filepath.folderName.toLower;
						buffers[name.asSymbol] = buffers[name.asSymbol].add(buf);
						delay.wait;
					}
				};
				folderPath.basename.post; " ".post;
			};
			"\nfiles loaded\n\n".post;
		}.fork(AppClock);
	}

	freeSoundFiles {
		buffers.do { |x| x.asArray.do { |buf| buf.free } };
		buffers = ();
	}

	loadSynthDefs { |path|
		var filePaths;
		path = path ?? { "synths".resolveRelative };
		filePaths = pathMatch(path +/+ "*");
		filePaths.do { |filepath|
			if(filepath.splitext.last == "scd") {
				(dirt:this).use { filepath.load }; "loading synthdefs in %\n".postf(filepath)
			}
		}
	}

	initVowels { |register|
		vowels = ();
		if(Vowel.formLib.at(\a).at(register).isNil) {
			"This voice register (%) isn't avaliable. Using counterTenor instead".format(register).warn;
			"Available registers are: %".format(Vowel.formLib.at(\a).keys).postln;
			register = \counterTenor;
		};

		[\a, \e, \i, \o, \u].collect { |x|
			vowels[x] = Vowel(x, register)
		};
	}


}


DirtBus {

	var <dirt, <port, <server;
	var <outBus, <senderAddr, <replyAddr;
	var <synthBus, <globalEffectBus;
	var group, globalEffects, netResponders;
	var <>releaseTime = 0.02;

	*new { |dirt, port = 57120, outBus = 0, senderAddr|
		^super.newCopyArgs(dirt, port, dirt.server, outBus, senderAddr).init
	}

	init {
		if(server.serverRunning.not) {
			Error("SuperColldier server '%' not running. Couldn't start DirtBus".format(server.name)).warn;
			^this
		};
		group = server.nextPermNodeID;
		globalEffects = ();
		synthBus = Bus.audio(server, dirt.numChannels);
		globalEffectBus = Bus.audio(server, dirt.numChannels);
		this.initNodeTree;
		this.openNetworkConnection;
		ServerTree.add(this, server); // synth node tree init
	}

	doOnServerTree {
		// on node tree init:
		this.initNodeTree
	}

	initNodeTree {
		server.makeBundle(nil, { // make sure they are in order
			server.sendMsg("/g_new", group, 0, 1);
			[\dirt_limiter, \dirt_delay].do { |name|
				globalEffects[name] = Synth.after(group, name.asString ++ dirt.numChannels,
					[\out, outBus, \effectBus, globalEffectBus]
				);
			}
		})
	}

	free {
		this.closeNetworkConnection;
		ServerTree.remove(this, server);
		globalEffects.do(_.release);
		server.freePermNodeID(group);
		synthBus.free;
		globalEffectBus.free;
	}

	sendSynth { |instrument, args, synthGroup = -1|
		//args.asOSCArgArray.postln; "--------------".postln;
		server.sendMsg(\s_new, instrument,
			-1, // no id
			1, // add action: addToTail
			synthGroup, // send to group
			*args.asOSCArgArray // append all other args
		)
	}


	// This implements an alternative API, to be accessed via OSC by "/play2"

	value2 { |args| // args are in the shape [key, val, key, val ...]
		this.performKeyValuePairs(\value, args)
	}


	// This implements the Dirt OSC API, to be accessed via OSC by "/play"

	value {
		|latency, cps = 1, sound, offset = 0, start = 0, end = 1, speed = 1, pan = 0, velocity,
		vowel, cutoff = 300, resonance = 0.5,
		accelerate = 0, shape = 0, krio, gain = 1, cutgroup = 0,
		delay = 0, delaytime = 0, delayfeedback = 0,
		crush = 0,
		coarse = 0,
		hcutoff = 0, hresonance = 0,
		bandqf = 0, bandq = 0,
		unit = \r|

		var amp, buffer, instrument, sample;
		var temp;
		var length, sampleRate, numFrames, bufferDuration;
		var sustain, startFrame, endFrame;
		var numChannels = dirt.numChannels;
		var synthGroup, monitorID;



		/*
		"cps: %, sound: %, offset: %, start: %, end: %, speed: %, pan: %, velocity: %, vowel: %, cutoff: %, resonance: %, accelerate: %, shape: %, krio: %, gain: %, cutgroup: %, delay: %, delaytime: %, delayfeedback: %, crush: %, coarse: %, hcutoff: %, hresonance: %, bandqf: %, bandq: %,unit: %"
		.format(cps, sound, offset, start, end, speed, pan, velocity,
		vowel, cutoff, resonance,
		accelerate, shape, krio, gain, cutgroup,
		delay, delaytime, delayfeedback,
		crush,
		coarse,
		hcutoff, hresonance,
		bandqf, bandq,
		unit).postln;
		*/


		buffer = dirt.getBuffer(sound);

		if(buffer.notNil) {
			if(buffer.sampleRate.isNil) {
				"Dirt: buffer '%' not yet completely read".format(sound).warn; ^this
			};
			numFrames = buffer.numFrames;
			bufferDuration = buffer.duration;
			sampleRate = buffer.sampleRate;
			sample = sound.identityHash;
			instrument = format("dirt_sample_%_%", buffer.numChannels, numChannels);

		} {
			if(SynthDescLib.at(sound).notNil) {
				instrument = sound;
				sampleRate = server.sampleRate;
				numFrames = sampleRate; // assume one second
				bufferDuration = 1.0;
			} {
				"Dirt: no sample or instrument found for '%'.\n".postf(sound);
				^this
			}
		};

		if(end >= start) {
			if(speed < 0) { temp = end; end = start; start = temp };
			length = end - start;
		} {
			// backwards
			length = start - end;
			speed = speed.neg;
		};

		if(unit == \rate) { unit = \r }; // API adaption to tidal output
		unit = unit ? \r;
		amp = pow(gain, 4);

		// sustain is the duration of the sample
		switch(unit,
			\r, {
				sustain = bufferDuration * length / speed;
				startFrame = numFrames * start;
				endFrame = numFrames * end;
			},
			\c, {
				sustain = length / cps;
				speed = speed * cps;
				startFrame = numFrames * start;
				endFrame = numFrames * end;
			},
			\s, {
				sustain = length;
				startFrame = sampleRate * start;
				endFrame = sampleRate * end;
			}
		);

		//unit.postln;
		//[\end_start, endFrame - startFrame / sampleRate, \sustain, sustain].postln;

		if(accelerate != 0) {
			// assumes linear acceleration
			sustain = sustain + (accelerate * sustain * 0.5 * speed.sign.neg);
		};

		synthGroup = server.nextNodeID;
		monitorID = server.nextNodeID;
		latency = latency ? 0.0 + server.latency;

		server.makeBundle(latency, { // use this to build a bundle

			if(cutgroup != 0) {
				server.sendMsg(\n_set, group, \gateCutGroup, cutgroup, \gateSample, sample);
			};

			// set global delay synth parameters
			if(delaytime > 0 or: { delayfeedback > 0 }) {
				server.sendMsg(\n_set, globalEffects[\dirt_delay].nodeID,
					\delaytime, delaytime,
					\delayfeedback, delayfeedback
				);
			};

			server.sendMsg(\g_new, synthGroup, 1, group); // make new group. it is freed from the monitor.


			this.sendSynth(instrument, [
				sustain: sustain,
				speed: speed,
				bufnum: buffer,
				start: start,
				end: end,
				startFrame: startFrame,
				endFrame: endFrame,
				pan: pan,
				accelerate: accelerate,
				offset: offset,
				cps: cps,
				out: synthBus],
			synthGroup
			);

			if(vowel.notNil) {
				vowel = dirt.vowels[vowel];
				if(vowel.notNil) {
					this.sendSynth("dirt_vowel" ++ numChannels,
						[
							out: synthBus,
							vowelFreqs: vowel.freqs,
							vowelAmps: vowel.amps,
							vowelRqs: vowel.rqs,
							resonance: resonance,
						],
						synthGroup
					)
				}

			};

			if(shape != 0) {
				shape = (2.0 * shape) / (1.0 - shape);
				this.sendSynth("dirt_shape" ++ numChannels,
					[
						shape: shape,
						out: synthBus
					],
					synthGroup
				)
			};

			if(hcutoff != 0) {
				this.sendSynth("dirt_hpf" ++ numChannels,
					[
						hcutoff: hcutoff,
						hresonance: hresonance,
						out: synthBus
					],
					synthGroup
				)
			};

			if(bandqf != 0) {
				this.sendSynth("dirt_bpf" ++ numChannels,
					[
						bandqf: bandqf,
						bandq: bandq,
						out: synthBus
					],
					synthGroup
				)
			};

			if(crush != 0) {
				this.sendSynth("dirt_crush" ++ numChannels,
					[
						crush: crush,
						out: synthBus
					],
					synthGroup
				)
			};

			if(coarse > 1) { // coarse == 1 => full rate
				this.sendSynth("dirt_coarse" ++ numChannels,
					[
						coarse: coarse,
						out: synthBus
					],
					synthGroup
				)
			};


			server.sendMsg(\s_new, "dirt_monitor" ++ numChannels,
				monitorID,
				3, // add action: addAfter
				synthGroup, // send to group
				*[
					in: synthBus,  // read from private
					out: outBus,     // write to outBus,
					globalEffectBus: globalEffectBus,
					effectAmp: delay,
					amp: amp,
					cutGroup: cutgroup.abs, // ignore negatives here!
					sample: sample, // required for the cutgroup mechanism
					sustain: sustain, // after sustain, free all synths and group
					release: releaseTime // fade out
				].asOSCArgArray // append all other args
			);


		});

		// free group after sustain: this won't be needed after doneAction 14 works in SC 3.7.0
		/*
		server.sendBundle(latency + sustain + releaseTime,
			["/error", -1], // surpress error whe it has been freed already by a cut
			["/n_free", monitorID]
			["/n_free", synthGroup]
		);
		*/


	}


	openNetworkConnection {

		this.closeNetworkConnection;

		// current standard protocol

		netResponders.add(

			OSCFunc({ |msg, time, tidalAddr|
				var latency = time - Main.elapsedTime;
				if(latency > 2) {
					"The scheduling delay is too long. Your networks clocks may not be in sync".warn;
					latency = 0.2;
				};
				replyAddr = tidalAddr; // collect tidal reply address
				this.value(latency, *msg[1..]);
			}, '/play', senderAddr, recvPort: port).fix

		);

		netResponders.add(
			// an alternative protocol, uses pairs of parameter names and values in arbitrary order
			OSCFunc({ |msg, time, tidalAddr|
				var latency = time - Main.elapsedTime;
				if(latency > 2) {
					"The scheduling delay is too long. Your networks clocks may not be in sync".warn;
					latency = 0.2;
				};
				replyAddr = tidalAddr; // collect tidal reply address
				this.value2([\latency, latency] ++ msg[2..]);
			}, '/play2', senderAddr, recvPort: port).fix
		);

		"SuperDirt: listening to Tidal on port %".format(port).postln;
	}

	closeNetworkConnection {
		netResponders.do { |x| x.free };
		netResponders = List.new;
	}

	sendToTidal { |args|
		if(replyAddr.notNil) {
			replyAddr.sendMsg(*args);
		} {
			"Currently no connection back to tidal".warn;
		}
	}

}