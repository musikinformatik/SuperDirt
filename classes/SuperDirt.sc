/*

SuperCollider implementation of Dirt

This object handles OSC communication and local effects.
These are relative to a server and a number of output channels
It keeps a number of dirt orbits (see below).


*/

SuperDirt {

	var <numChannels, <server;
	var <soundLibrary, <vowels;
	var <>orbits;
	var <>modules;

	var <port, <senderAddr, <replyAddr, netResponders;
	var <>receiveAction, <>warnOutOfOrbit = true, <>maxLatency = 42;

	classvar <>default, <>maxSampleNumChannels = 2;

	*new { |numChannels = 2, server|
		^super.newCopyArgs(numChannels, server ? Server.default).init
	}

	*initClass {
		Event.addEventType(\dirt, {
			var keys, values;
			var dirt = ~dirt ? SuperDirt.default;
			~delta = ~delta ?? { ~stretch.value * ~dur.value };
			~latency = ~latency ?? { dirt.server.latency };
			if(~n.isArray) {
				keys = currentEnvironment.keys.asArray;
				values = keys.collect(_.envirGet).flop;
				values.do { |each|
					var e = Event(parent: currentEnvironment);
					keys.do { |key, i| e.put(key, each.at(i)) };
					dirt.orbits.wrapAt(e[\orbit] ? 0).value(e)
				}
			} {
				dirt.orbits.wrapAt(~orbit ? 0).value(currentEnvironment)
			}
		});

		Event.addEventType(\tidalmidi, #{|server|

			var freqs, lag, sustain, strum;
			var args, midiout, hasGate, midicmd, latency;

			freqs = ~freq.value;

			~amp = ~amp.value;
			~midinote = (freqs.cpsmidi).round(1).asInteger;
			strum = ~strum;
			lag = ~lag + ~latency;
			sustain = ~sustain = ~sustain.value;
			midiout = ~midiout.value;
			~uid ?? { ~uid = midiout.uid };  // mainly for sysex cmd
			hasGate = ~hasGate ? true; // TODO
			midicmd = ~midicmd ? \noteOn;
			~ctlNum = ~ctlNum ? 0;

			args = ~midiEventFunctions[midicmd].valueEnvir.asCollection;

			latency = i * strum + lag;

			if(latency == 0.0) {
				midiout.performList(midicmd, args)
			} {
				thisThread.clock.sched(latency, {
					midiout.performList(midicmd, args);
				})
			};
			if(hasGate and: { midicmd === \noteOn }) {
				thisThread.clock.sched(sustain + latency, {
					midiout.noteOff(*args)
				});
			};

		})
	}

	init {
		soundLibrary = DirtSoundLibrary(server, numChannels);
		modules = [];
		this.loadSynthDefs;
		this.initVowels(\counterTenor);
	}


	start { |port = 57120, outBusses, senderAddr = (NetAddr("127.0.0.1"))|
		if(orbits.notNil) { this.stop };
		this.makeOrbits(outBusses ? [0]);
		this.connect(senderAddr, port)
	}

	stop {
		orbits.do(_.free);
		orbits = nil;
		this.closeNetworkConnection;
	}

	makeOrbits { |outBusses|
		var new;
		new = outBusses.asArray.collect(DirtOrbit(this, _));
		orbits = orbits ++ new;
		^new.unbubble
	}

	set { |...pairs|
		orbits.do(_.set(*pairs))
	}

	free {
		soundLibrary.free;
		this.stop;
	}

	/* sound library */

	soundLibrary_ { |argSoundLibrary|
		if(argSoundLibrary.server !== server or: { argSoundLibrary.numChannels != numChannels }) {
			Error("The number of channels and the server of a sound library have to match.").throw
		};
		soundLibrary = argSoundLibrary;
	}

	loadOnly { |names, path, appendToExisting = false|
		soundLibrary.loadOnly(names, path, appendToExisting )
	}

	loadSoundFileFolder { |folderPath, name, appendToExisting = false|
		soundLibrary.loadSoundFileFolder(folderPath, name, appendToExisting)
	}

	loadSoundFiles { |paths, appendToExisting = false, namingFunction|
		soundLibrary.loadSoundFiles(paths, appendToExisting = false, namingFunction)
	}

	loadSoundFile { |path, name, appendToExisting = false|
		soundLibrary.loadSoundFile(path, name, appendToExisting)
	}

	freeAllSoundFiles {
		soundLibrary.freeAllSoundFiles
	}

	freeSoundFiles { |names|
		soundLibrary.freeSoundFiles(names)
	}

	postSampleInfo {
		soundLibrary.postSampleInfo
	}

	verbose_ { |bool|
		soundLibrary.verbose_(bool)
	}

	verbose {
		^soundLibrary.verbose
	}

	buffers { ^soundLibrary.buffers }
	fileExtensions { ^soundLibrary.fileExtensions }
	fileExtensions_ { |list| ^soundLibrary.fileExtensions_(list) }


	/* modules */

	addModule { |name, func, test|
		var index, module;
		name = name.asSymbol;
		// the order of modules determines the order of synths
		// when replacing a module, we don't change the order
		module = DirtModule(name, func, test);
		index = modules.indexOfEqual(module);
		if(index.isNil) { modules = modules.add(module) } { modules.put(index, module) };
	}

	removeModule { |name|
		modules.removeAllSuchThat { |x| x.name == name }
	}

	getModule { |name|
		^modules.detect { |x| x.name == name }
	}

	clearModules {
		modules = [];
	}

	addFilterModule { |synthName, synthFunc, test|
		var instrument = synthName ++ numChannels;
		SynthDef(instrument, synthFunc).add;
		this.addModule(synthName, { |dirtEvent| dirtEvent.sendSynth(instrument) }, test);
	}

	orderModules { |names| // names provide some partial order
		var allNames = modules.collect { |x| x.name };
		var first = names.removeAt(0);
		var rest = difference(allNames, names);
		var firstIndex = rest.indexOf(first) ? -1 + 1;
		names = rest.insert(firstIndex, names).flatten;
		"new module order: %".format(names).postln;
		modules = names.collect { |x| this.getModule(x) }.reject { |x| x.isNil }
	}


	// SynthDefs are signal processing graph definitions
	// this is also where the modules are added

	loadSynthDefs { |path|
		var filePaths;
		path = path ?? { "../synths".resolveRelative };
		filePaths = pathMatch(standardizePath(path +/+ "*"));
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


	connect { |argSenderAddr, argPort|

		if(Main.scVersionMajor == 3 and: { Main.scVersionMinor == 6 }) {
			"Please note: SC3.6 listens to any sender.".warn;
			senderAddr = nil;
		} {
			senderAddr = argSenderAddr
		};

		port = argPort;

		this.closeNetworkConnection;

		netResponders.add(
			// pairs of parameter names and values in arbitrary order
			OSCFunc({ |msg, time, tidalAddr|
				var latency = time - Main.elapsedTime;
				var event = (), orbit, index;
				if(latency > maxLatency) {
					"The scheduling delay is too long. Your networks clocks may not be in sync".warn;
					latency = 0.2;
				};
				replyAddr = tidalAddr; // collect tidal reply address
				event[\latency] = latency;
				event.putPairs(msg[1..]);
				receiveAction.value(event);
				index = event[\orbit] ? 0;

				if(warnOutOfOrbit and: { index >= orbits.size } or: { index < 0 }) {
						"SuperDirt: event falls out of existining orbits, index (%)".format(index).warn
				};

				DirtEvent(orbits @@ index, modules, event).play

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

	*postTidalParameters { |synthNames, excluding |
		var descs, paramString, parameterNames;

		excluding = this.predefinedSynthParameters ++ excluding;

		descs = synthNames.asArray.collect { |name| SynthDescLib.at(name) };
		descs = descs.reject { |x, i|
			var notFound = x.isNil;
			if(notFound) { "no Synth Description with this name found: %".format(synthNames[i]).warn; ^this };
			notFound
		};



		parameterNames = descs.collect { |x|
			x.controls.collect { |y| y.name }
		};
		parameterNames = parameterNames.flat.as(Set).as(Array).sort.reject { |x| excluding.includes(x) };
		paramString = this.tidalParameterString(parameterNames);

		^"\n-- | parameters for the SynthDefs: %\nlet %\n\n".format(synthNames.join(", "), paramString)

	}

	*tidalParameterString { |keys|
		^keys.collect { |x| format("(%, %_p) = pF \"%\" (Nothing)", x, x, x) }.join("\n    ");
	}

	*predefinedSynthParameters {
		// not complete, but avoids obvious collisions
		^#[\pan, \amp, \out, \i_out, \sustain, \gate, \accelerate, \gain, \unit, \cut, \octave, \offset, \attack];
	}


}

/*

An orbit encapsulates a continuous state that affects all sounds played in it.
It has default parameters for all sounds, which can be set, e.g. pan, and which can be overridden from tidal.
Its globalEffects are e.g. delay, reverb, and also the monitor which handles the audio output routing.
You can add and remove effects at runtime.

Settable parameters are also:

- fadeTime (fade in and out of each sample grain)
- amp (gain)
- minSustain (samples shorter than that are dropped).
- outBus (channel offset for the audio output)

Via the defaultParentEvent, you can also set parameters (use the set message):

- lag (offset all events)
- lock (if set to 1, syncs delay times with cps)


*/


DirtOrbit {

	var <dirt, <server, <outBus;
	var <synthBus, <globalEffectBus, <dryBus;
	var <group, <globalEffects, <cutGroups;
	var <>minSustain;


	var <>defaultParentEvent;

	*new { |dirt, outBus|
		^super.newCopyArgs(dirt, dirt.server, outBus).init
	}

	init {
		if(server.serverRunning.not) {
			Error("SuperColldier server '%' not running. Couldn't start DirtOrbit".format(server.name)).warn;
			^this
		};
		group = server.nextPermNodeID;
		cutGroups = IdentityDictionary.new;
		synthBus = Bus.audio(server, dirt.numChannels);
		dryBus = Bus.audio(server, dirt.numChannels);
		globalEffectBus = Bus.audio(server, dirt.numChannels);
		minSustain = 8 / server.sampleRate;
		this.initDefaultGlobalEffects;
		this.initNodeTree;
		this.makeDefaultParentEvent;

		ServerTree.add(this, server); // synth node tree init
		CmdPeriod.add(this);
	}

	initDefaultGlobalEffects {
		this.globalEffects = [
			GlobalDirtEffect(\dirt_delay, [\delaytime, \delayfeedback, \delayAmp, \lock, \cps]),
			GlobalDirtEffect(\dirt_reverb, [\size, \room, \dry]),
			GlobalDirtEffect(\dirt_leslie, [\leslie, \lrate, \lsize]),
			GlobalDirtEffect(\dirt_monitor, [\dirtOut])
		]
	}

	globalEffects_ { |array|
		globalEffects = array.collect { |x| x.numChannels = dirt.numChannels }
	}

	doOnServerTree {
		// on node tree init:
		this.initNodeTree
	}

	cmdPeriod {
		cutGroups.clear
	}

	initNodeTree {
		server.makeBundle(nil, { // make sure they are in order
			server.sendMsg("/g_new", group, 0, 1); // make sure group exists
			globalEffects.reverseDo { |x| x.play(group, outBus, dryBus, globalEffectBus) };
		})
	}

	value { |event|
		DirtEvent(this, dirt.modules, event).play
	}

	valuePairs { |pairs|
		this.value((latency: server.latency).putPairs(pairs));
	}

	outBus_ { |bus|
		outBus = bus;
		this.initNodeTree;
	}

	set { |...pairs|
		pairs.pairsDo { |key, val|
			defaultParentEvent.put(key, val)
		}
	}

	get { |key|
		^defaultParentEvent.at(key)
	}

	amp_ { |val|
		this.set(\amp, val)
	}

	amp {
		^this.get(\amp)
	}

	fadeTime_ { |val|
		this.set(\fadeTime, val)
	}

	fadeTime {
		^this.get(\fadeTime)
	}

	freeSynths {
		server.bind {
			server.sendMsg("/n_free", group);
			this.initNodeTree
		}
	}

	free {
		dirt.closeNetworkConnection;
		ServerTree.remove(this, server);
		globalEffects.do(_.release);
		server.freePermNodeID(group);
		synthBus.free;
		globalEffectBus.free;
		cutGroups.clear;
	}

	getCutGroup { |id|
		var cutGroup = cutGroups.at(id);
		if(cutGroup.isNil) {
			cutGroup = server.nextNodeID;
			server.sendMsg("/g_new", cutGroup, 1, group);
			cutGroups.put(id, cutGroup);
		}
		^cutGroup
	}


	makeDefaultParentEvent {
		defaultParentEvent = Event.make {

			~cps = 1.0;
			~offset = 0.0;
			~begin = 0.0;
			~end = 1.0;
			~speed = 1.0;
			~pan = 0.5;
			~gain = 1.0;
			~cut = 0.0;
			~unit = \r;
			~n = 0; // sample number or note
			~octave = 5;
			~midinote = #{ ~n + (~octave * 12) };
			~freq = #{ ~midinote.midicps };
			~delta = 1.0;

			~latency = 0.0;
			~lag = 0.0;
			~length = 1.0;
			~loop = 1.0;
			~dry = 0.0;
			~lock = 0; // if set to 1, syncs delay times with cps

			~amp = 0.4;
			~fadeTime = 0.001;


			// values from the dirt bus
			~orbit = this;
			~dirt = dirt;
			~out = synthBus;
			~dryBus = dryBus;
			~effectBus = globalEffectBus;
			~numChannels = dirt.numChannels;
			~server = server;

			~notFound = {
				"no synth or sample named '%' could be found.".format(~s).postln;
			};

		}
	}


}


// DirtModules encapsulate two functions:
// 1) for testing for parameters (whether or not to start a synth at all)
// 2) activated when the parameters are found in the message from tidal


DirtModule {
	var <name, <func, <test;

	*new { |name, func, test|
		^super.newCopyArgs(name, func, test ? true)
	}

	value { |orbit|
		if(test.value, { func.value(orbit) })
	}

	== { arg that;
		^this.compareObject(that, #[\name])
	}

	hash {
		^this.instVarHash(#[\name])
	}

	printOn { |stream|
		stream  << this.class.name << "(" <<< name << ")"
	}

	storeArgs {
		^[name, func, test]
	}
}

// this keeps state of running synths that have a livespan of the DirtOrbit
// sends only OSC when an update is necessary

// "name" is the name of the SynthDef
// (for each possible number of channels appended by a number, see: core-synths)
// "paramNames" is an array of keys (symbols) which to look up as arguments
// "numChannels" is the number of synth channels (no need to specify if you use it in a DirtOrbit)


GlobalDirtEffect {

	var <>name, <>paramNames, <>numChannels, <state;
	var synth, defName;

	*new { |name, paramNames, numChannels|
		^super.newCopyArgs(name, paramNames, numChannels, ())
	}

	play { |group, outBus, dryBus, effectBus|
		this.release;
		synth = Synth.after(group, name.asString ++ numChannels,
			[\outBus, outBus, \dryBus, dryBus, \effectBus, effectBus] ++ state.asPairs
		)
	}

	release { |releaseTime = 0.2|
		if(synth.notNil) {
			// surpress error, because we don't keep track of server state
			synth.server.sendBundle(nil,
				['/error', -1],
				[15, synth.nodeID, \gate, -1.0 - releaseTime],
				['/error', -2]
			);
		};
	}

	set { |event|
		var argsChanged, someArgsNotNil = false;
		paramNames.do { |key|
			var value = event[key];
			value !? { someArgsNotNil = true };
			if(state[key] != value) {
				argsChanged = argsChanged.add(key).add(value);
				state[key] = value;
			}
		};
		if(someArgsNotNil) { synth.run };
		if(argsChanged.notNil) {
			synth.set(*argsChanged);
		}
	}

	printOn { |stream|
		stream  << this.class.name << "(" <<<* [name, paramNames] << ")"
	}

	storeArgs {
		^[name, paramNames, numChannels]
	}

}
