/*

SuperCollider implementation of Dirt

*/

SuperDirt {

	var <numChannels, <server;
	var <buffers, <vowels;
	var <>orbits;
	var <>modules;

	var  <port, <senderAddr, <replyAddr, netResponders;

	classvar <>maxSampleNumChannels = 2;

	*new { |numChannels = 2, server|
		^super.newCopyArgs(numChannels, server ? Server.default).init
	}

	init {
		buffers = ();
		modules = [];
		this.loadSynthDefs;
		this.initVowels(\counterTenor);
	}

	start { |port = 57120, outBusses = 0, senderAddr = (NetAddr("127.0.0.1"))|
		if(orbits.notNil) { this.stop };
		this.makeBusses(outBusses);
		this.connect(senderAddr, port)
	}

	stop {
		orbits.do(_.free);
		orbits = nil;
	}

	makeBusses { |outBusses|
		var new;
		new = outBusses.collect(DirtOrbit(this, _));
		orbits = orbits ++ new;
		^new.unbubble
	}

	free {
		this.freeSoundFiles;
		this.stop;
	}

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

	getBuffer { |key, index|
		var allbufs = buffers[key];
		if(allbufs.isNil) { ^nil };
		^allbufs.wrapAt(index.asInteger)
	}

	loadSoundFiles { |path, fileExtension = "wav"|
		var folderPaths;
		if(server.serverRunning.not) {
			"Superdirt: server not running - cannot load sound files.".warn; ^this
		};
		path = path ?? { "../../Dirt-Samples/".resolveRelative };
		folderPaths = pathMatch(standardizePath(path +/+ "**"));
		"\nloading sample banks:\n".post;
		folderPaths.do { |folderPath|
			PathName(folderPath).filesDo { |filepath|
				var buf, name;
				if(filepath.extension.find(fileExtension, true).notNil) {
					buf = Buffer.readWithInfo(server, filepath.fullPath);
					name = filepath.folderName.toLower;
					buffers[name.asSymbol] = buffers[name.asSymbol].add(buf);
				}
			};
			folderPath.basename.post; " ".post;
		};
		"\nfiles loaded\n\n".post;
	}

	freeSoundFiles {
		buffers.do { |x| x.asArray.do { |buf| buf.free } };
		buffers = ();
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
				var event = (), orbit;
				if(latency > 2) {
					"The scheduling delay is too long. Your networks clocks may not be in sync".warn;
					latency = 0.2;
				};
				replyAddr = tidalAddr; // collect tidal reply address
				event[\latency] = latency;
				event.putPairs(msg[1..]);
				orbit = orbits @@ (event[\orbit] ? 0);
				DirtEvent(orbit, modules, event).play
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


DirtOrbit {

	var <dirt, <server, <outBus;
	var <synthBus, <globalEffectBus, <dryBus;
	var <group, <globalEffects;
	var <>fadeTime = 0.001, <>amp = 0.4, <>minSustain;


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
		synthBus = Bus.audio(server, dirt.numChannels);
		dryBus = Bus.audio(server, dirt.numChannels);
		globalEffectBus = Bus.audio(server, dirt.numChannels);
		minSustain = 8 / server.sampleRate;
		this.initDefaultGlobalEffects;
		this.initNodeTree;
		this.makeDefaultParentEvent;

		ServerTree.add(this, server); // synth node tree init
	}

	initDefaultGlobalEffects {
		this.globalEffects = [
			GlobalDirtEffect(\dirt_delay, [\delaytime, \delayfeedback, \delayAmp, \lock, \cps]),
			GlobalDirtEffect(\dirt_reverb, [\size, \room, \dry]),
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
	}

	makeDefaultParentEvent {
		defaultParentEvent = Event.make {

			~cps = 1.0;
			~offset = 0.0;
			~begin = 0.0;
			~end = 1.0;
			~speed = 1.0;
			~pan = 0.5;
			~accelerate = 0.0;
			~gain = 1.0;
			~cut = 0.0;
			~unit = \r;
			~n = 0; // sample number or note
			~loop = 0;

			~latency = 0.0;
			~length = 1.0;
			~sustain = 1.0;
			~unitDuration = 1.0;
			~dry = 0.0;
			~lock = 0; // if set to 1, syncs delay times with cps

			// values from the dirt bus
			~orbit = this;
			~dirt = dirt;
			~out = synthBus;
			~dryBus = dryBus;
			~effectBus = globalEffectBus;
			~numChannels = dirt.numChannels;
			~server = server;

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

// this keeps state of running synths that have a livespan of the DirtBus
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
		var argsChanged;
		paramNames.do { |key|
			var value = event[key];
			if(state[key] != value) {
				argsChanged = argsChanged.add(key).add(value);
				state[key] = value;
			}
		};
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

