/*

SuperCollider implementation of Dirt

Requires: sc3-plugins, Vowel Quark


Open Qustions:

* should accelerate reduce the playback time? (currently: yes)
* should samples reverse when accelerate is negative and large? (currently: no)
* is accelerate direction relative to rate or absolute? (currently: absolute)

TODO:
* let's make a nice protocol of how to extend it better

One first step would be: Tidal sends pairs of argument names and values
Then we could map arguments to effects, and new effects could easity be added

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
		this.initSynthDefs(numChannels, maxSampleNumChannels);
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

	loadSoundFiles { |path, fileExtension = "wav", sync = false|
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
						if(sync) { server.sync };
						name = filepath.folderName.toLower;
						buffers[name.asSymbol] = buffers[name.asSymbol].add(buf)
					}
				};
				folderPath.basename.post; " ".post;
			};
			"\n\n".post;
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
				try { (dirt:this).use { filepath.load }; "loading synthdefs in %\n".postf(filepath) } { |err| err.postln };
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

	initSynthDefs { |numChannels = 2, maxSampleNumChannels = 2|

		// global synth defs: these synths run in each DirtBus and are only released when it is stopped

		SynthDef("dirt_delay" ++ numChannels, { |out, effectBus, gate = 1, delaytime, delayfeedback|
			var signal = In.ar(effectBus, numChannels);
			signal = SwitchDelay.ar(signal, 1, 1, delaytime, delayfeedback); // from sc3-plugins
			signal = signal * EnvGen.kr(Env.asr, gate, doneAction:2);
			Out.ar(out, signal);
		}).add;

		SynthDef("dirt_limiter" ++ numChannels, { |out, gate = 1|
			var signal = In.ar(out, numChannels);
			signal = signal * EnvGen.kr(Env.asr, gate, doneAction:2);
			ReplaceOut.ar(out, Limiter.ar(signal))
		}).add;

		// thanks to Jost Muxfeld:

		SynthDef("dirt_reverb"  ++ numChannels, { |out, effectBus, gate = 1, amp = 0.1, depth = 0.4|
			var in, snd, loop;

			in = In.ar(effectBus, numChannels).asArray.sum;

			4.do { in = AllpassN.ar(in, 0.03, { Rand(0.005, 0.02) }.dup(numChannels), 1) };


			depth = depth.linlin(0, 1, 0.1, 0.98); // change depth between 0.1 and 0.98
			loop = LocalIn.ar(numChannels) * { depth + Rand(0, 0.05) }.dup(numChannels);
			loop = OnePole.ar(loop, 0.5);  // 0-1

			loop = AllpassN.ar(loop, 0.05, { Rand(0.01, 0.05) }.dup(numChannels), 2);

			loop = DelayN.ar(loop, 0.3, [0.19, 0.26] + { Rand(-0.003, 0.003) }.dup(2));
			loop = AllpassN.ar(loop, 0.05, { Rand(0.03, 0.15) }.dup(numChannels), 2);

			loop = LeakDC.ar(loop);
			loop = loop + in;

			LocalOut.ar(loop);

			snd = Delay2.ar(loop);
			snd = snd * EnvGen.kr(Env.asr, gate, doneAction:2);

			Out.ar(out, snd * amp);

		}).add;


		// write variants for different sample buffer sizes
		(1..maxSampleNumChannels).do { |sampleNumChannels|

			var name = format("dirt_sample_%_%", sampleNumChannels, numChannels);

			SynthDef(name, { |bufnum, startFrame, endFrame,
				pan = 0, amp = 0.1, speed = 1, accelerate = 0, keepRunning = 0|

				var sound, rate, phase, krPhase, endGate;

				// bufratescale adjusts the rate if sample doesn't have the same rate as soundcard
				rate = speed + Sweep.kr(rate: accelerate);

				// sample phase
				phase =  Sweep.ar(1, rate * BufSampleRate.kr(bufnum)) + startFrame;

				sound = BufRd.ar(
					numChannels: sampleNumChannels,
					bufnum: bufnum,
					phase: phase,
					loop: 0, // should we loop?
					interpolation: 4 // cubic interpolation
				);

				this.panOut(sound, pan, amp);
			}).add;
		};

		/*
		Add Effect SynthDefs
		These per-sample-effects are freed after Monitor envelope has ended
		*/


		SynthDef("dirt_vowel" ++ numChannels, { |out, resonance = 0.5, vowel|
			var signal, vowelFreqs, vowelAmps, vowelRqs;
			signal = In.ar(out, numChannels);
			vowelFreqs = \vowelFreqs.ir(1000 ! 5);
			vowelAmps = \vowelAmps.ir(0 ! 5) * resonance.linlin(0, 1, 50, 350);
			vowelRqs = \vowelRqs.ir(0 ! 5) * resonance.linlin(0, 1, 1, 0.1) * 2;
			//vowelRqs = \vowelRqs.ir(0 ! 5) * resonance.linexp(0, 1, 0.01, 0.2);
			signal = BPF.ar(signal, vowelFreqs, vowelRqs, vowelAmps).sum;
			//signal = Formlet.ar(signal, vowelFreqs, 0.005, vowelRqs);
			ReplaceOut.ar(out, signal);

		}).add;

		// would be nice to have some more parameters in some cases

		SynthDef("dirt_crush" ++ numChannels, { |out, crush = 4|
			var signal = In.ar(out, numChannels);
			signal = signal.round(0.5 ** crush);
			ReplaceOut.ar(out, signal)
		}).add;


		SynthDef("dirt_coarse" ++ numChannels, { |out, coarse = 0, bandq = 10|
			var signal = In.ar(out, numChannels);
			signal = Latch.ar(signal, Impulse.ar(SampleRate.ir / coarse));
			ReplaceOut.ar(out, signal)
		}).add;

		SynthDef("dirt_hpf" ++ numChannels, { |out, hcutoff = 440, hresonance = 0|
			var signal = In.ar(out, numChannels);
			signal = RHPF.ar(signal, hcutoff, hresonance.linexp(0, 1, 1, 0.001));
			ReplaceOut.ar(out, signal)
		}).add;

		SynthDef("dirt_bpf" ++ numChannels, { |out, bandqf = 440, bandq = 10|
			var signal = In.ar(out, numChannels);
			signal = BPF.ar(signal, bandqf, 1/bandq) * max(bandq, 1.0);
			ReplaceOut.ar(out, signal)
		}).add;


		// the monitor does the mixing and zeroing of the busses for each sample grain
		// so that they can all play in one bus

		SynthDef("dirt_monitor" ++ numChannels, { |out, in, globalEffectBus, effectAmp = 0, sustain = 1, release = 0.02|
			var signal = In.ar(in, numChannels);
			//  doneAction:13 = must release all other synths in group.
			// ideally, 14 but it doesn't work before 9d15cdc746627829a9598694cf4feaa6aab0bd90.
			signal = signal * this.releaseAfter(sustain, releaseTime: release, doneAction:2);
			Out.ar(out, signal);
			Out.ar(globalEffectBus, signal * effectAmp);
			ReplaceOut.ar(in, Silent.ar(numChannels)) // clears bus signal for subsequent synths
		}).add;

	}


	/*
	convenience methods for panning and releasing
	*/

	panOut { |signal, pan = 0.0, mul = 1.0|
		var output;

		if(numChannels == 2) {
			output = Pan2.ar(signal, (pan * 2) - 1, mul)
		} {
			output = PanAz.ar(numChannels, signal, pan, mul)
		};
		if(signal.size > 1) { output = output.sum };

		^OffsetOut.ar(\out.kr, output); // we create an out control argument in a different way here.
	}


	/*
	In order to avoid bookkeeping on the language side, we implement cutgroups as follows:
	The language initialises the synth with its sample id (some number that correlates with the sample name) and the cutgroup.
	Before we start the new synth, we send a /set message to all synths, and those that match the specifics will be released.
	*/

	gateCutGroup { |gate = 1, releaseTime = 0.02, doneAction = 2|
		// this is necessary because the message "==" tests for objects, not for signals
		var same = { |a, b| BinaryOpUGen('==', a, b) };
		var sameCutGroup = same.(\cutGroup.kr(0), abs(\gateCutGroup.kr(0)));
		var sameSample = same.(\sample.kr(0), \gateSample.kr(0));
		var which = \gateCutGroup.kr(0).sign; // -1, 0, 1
		var free = Select.kr(which + 1, // 0, 1, 2
			[
				sameSample,
				0.0, // default cut group 0 doesn't ever cut
				1.0
			]
		) * sameCutGroup; // same cut group is mandatory

		// this is a workaround for a somewhat broken behaviour of the doneAction 13
		EnvGen.kr(Env.asr(0, 1, releaseTime), (1 - free), doneAction:13);

		^EnvGen.ar(Env.asr(0, 1, releaseTime), (1 - free) * gate, doneAction:doneAction);
	}

	releaseWhenSilent { |signal|
		DetectSilence.ar(LeakDC.ar(signal.asArray.sum), doneAction:2);
	}

	releaseAfter { |sustain, releaseTime = 0.02, doneAction = 2|
		^this.gateCutGroup(EnvGen.kr(Env.linen(0, sustain, 0)), releaseTime, doneAction)
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
		accelerate = 0, shape, krio, gain = 1, cutgroup = 0,
		delay = 0, delaytime = 0, delayfeedback = 0,
		crush = 0,
		coarse = 0,
		hcutoff = 0, hresonance = 0,
		bandqf = 0, bandq = 0,
		unit = \r|

		var amp, allbufs, buffer;
		var instrument, key, index, sample;
		var temp;
		var length, sampleRate, numFrames, bufferDuration;
		var sustain, startFrame, endFrame;
		var numChannels = dirt.numChannels;
		var synthGroup;

		#key, index = sound.asString.split($:);
		key = key.asSymbol;
		allbufs = dirt.buffers[key];
		index = (index ? 0).asInteger;

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


		if(allbufs.notNil or: { SynthDescLib.at(key).notNil }) {


			if(allbufs.notNil) {
				buffer = allbufs.wrapAt(index);
				if(buffer.sampleRate.isNil) {
					"Dirt: buffer '%' not loaded yet".format(sound).warn; ^this
				};
				numFrames = buffer.numFrames;
				bufferDuration = buffer.duration;
				sampleRate = buffer.sampleRate;
				sample = sound.identityHash;
				instrument = format("dirt_sample_%_%", buffer.numChannels, numChannels);
			} {
				instrument = key;
				sampleRate = server.sampleRate;
				numFrames = sampleRate; // assume one second
				bufferDuration = 1.0;
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
			latency = latency ? 0.0 + server.latency;

			server.makeBundle(latency, { // use this to build a bundle

				if(cutgroup != 0) {
					server.sendMsg(\n_set, group, \gateCutGroup, cutgroup, \gateSample, sample);
				};

				// set global delay synth parameters
				if(delaytime != 0 or: { delayfeedback != 0 }) {
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
					amp: amp,
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


				this.sendSynth("dirt_monitor" ++ numChannels,
					[
						in: synthBus,  // read from private
						out: outBus,     // write to outBus,
						globalEffectBus: globalEffectBus,
						effectAmp: delay,
						cutGroup: cutgroup.abs, // ignore negatives here!
						sample: sample, // required for the cutgroup mechanism
						sustain: sustain, // after sustain, free all synths and group
						release: releaseTime // fade out
					],
					synthGroup
				);


			});

			// free group after sustain: this won't be needed after doneAction 14 works in SC 3.7.0

			server.sendBundle(latency + sustain + releaseTime,
				["/error", -1], // surpress error whe it has been freed already by a cut
				["/n_free", synthGroup]
			);


		} {
			"Dirt: no sample or instrument found for this sound: %\n".postf();
		}
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