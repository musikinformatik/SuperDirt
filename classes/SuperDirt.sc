/*

SuperCollider implementation of Dirt
version 0.2 (event-based)


Open Qustions:

* should accelerate reduce the playback time? (currently: yes)
* should samples reverse when accelerate is negative and large? (currently: no)
* is accelerate direction relative to rate or absolute? (currently: absolute)


*/

SuperDirt {

	var <numChannels, <server;
	var <buffers, <vowels;
	var <>dirtBusses;
	var <>modules;

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

	start { |ports = 57120, outBusses = 0, senderAddrs = (NetAddr("127.0.0.1"))|
		if(dirtBusses.notNil) { this.stop };
		this.connect(ports, outBusses, senderAddrs)
	}

	stop {
		dirtBusses.do(_.free);
		dirtBusses = nil;
	}

	connect { |ports = 57120, outBusses = 0, senderAddrs = (NetAddr("127.0.0.1"))|
		var connections;
		if(Main.scVersionMajor == 3 and: { Main.scVersionMinor == 6 }) {
			"Please note: SC3.6 listens to any sender.".warn;
			senderAddrs = nil;
		};
		connections = [ports, outBusses, senderAddrs].flop.collect(DirtBus(this, *_));
		dirtBusses = dirtBusses ++ connections;
		^connections.unbubble
	}

	free {
		this.freeSoundFiles;
		this.stop;
	}

	addModule { |name, func, test|
		var index, module;
		// the order of modules determines the order of synths
		// when replacing a module, we don't change the order
		module = DirtModule(name, func, test);
		index = modules.indexOfEqual(module);
		if(index.isNil) { modules = modules.add(module) } { modules.put(index, module) };
	}

	removeModule { |name|
		modules.removeAllSuchThat { |x| x.name == name }
	}

	clearModules {
		modules = [];
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
		path = path ?? { "../samples".resolveRelative };
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


}


DirtBus {

	var <dirt, <port, <server;
	var <outBus, <senderAddr, <replyAddr;
	var <synthBus, <globalEffectBus;
	var <group, <globalEffects, netResponders;
	var <>fadeTime = 0.001, <>amp = 0.4, <>minSustain;


	var <>defaultParentEvent;

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
		minSustain = 8 / server.sampleRate;
		this.initNodeTree;
		this.makeDefaultParentEvent;

		this.openNetworkConnection; // start listen
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

	outBus_ { |bus|
		globalEffects.do { |synth| synth.set(\out, bus) };
		outBus = bus;
	}

	free {
		this.closeNetworkConnection;
		ServerTree.remove(this, server);
		globalEffects.do(_.release);
		server.freePermNodeID(group);
		synthBus.free;
		globalEffectBus.free;
	}

	// This implements an alternative API, to be accessed via OSC by "/play2"

	value { |args| // args are in the shape [key, val, key, val ...]
		//if(args.first.isKindOf(Symbol).not) { "wrong tidal format, please set 'namedParams = True'".warn; ^this };
		DirtEvent(this, dirt.modules, args).play
	}

	// this implements the standard API, internally converting it

	value2 {
		|latency, cps = 1, sound, offset = 0, start = 0, end = 1, speed = 1, pan = 0, velocity,
		vowel, cutoff = 300, resonance = 0.5,
		accelerate = 0, shape = 0, krio, gain = 1, cutgroup = 0,
		delay = 0, delaytime = 0, delayfeedback = 0,
		crush = 0,
		coarse = 0,
		hcutoff = 0, hresonance = 0,
		bandqf = 0, bandq = 0,
		unit = \r|

		var args = [\latency, latency, \cps, cps, \sound, sound, \offset, offset, \start, start, \end, end, \speed, speed, \pan, pan, \velocity, velocity, \vowel, vowel, \cutoff, cutoff, \resonance, resonance, \accelerate, accelerate, \shape, shape, \krio, krio, \gain, gain, \cutgroup, cutgroup, \delay, delay, \delaytime, delaytime, \delayfeedback, delayfeedback, \crush, crush, \coarse, coarse, \hcutoff, hcutoff, \hresonance, hresonance, \bandqf, bandqf, \bandq, bandq, \unit, unit];


		this.value(args)


	}

	openNetworkConnection {

		this.closeNetworkConnection;

		netResponders.add(
			OSCFunc({ |msg, time, tidalAddr|
				var latency = time - Main.elapsedTime;
				if(latency > 2) {
					"The scheduling delay is too long. Your networks clocks may not be in sync".warn;
					latency = 0.2;
				};
				replyAddr = tidalAddr; // collect tidal reply address
				this.value2(latency, *msg[1..]);
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
				this.value([\latency, latency] ++ msg[2..]);
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

	set { |...pairs|
		pairs.pairsDo { |key, val|
			defaultParentEvent.put(key, val)
		}
	}


	makeDefaultParentEvent {
		defaultParentEvent = Event.make {

			~cps = 1.0;
			~offset = 0.0;
			~start = 0.0;
			~end = 1.0;
			~speed = 1.0;
			~pan = 0.0;
			~accelerate = 0.0;
			~gain = 1.0;
			~cutgroup = 0.0;
			~unit = \r;

			~latency = 0.0;
			~length = 1.0;
			~sustain = 1.0;
			~unitDuration = 1.0;

			// values from the dirt bus
			~dirtBus = this;
			~dirt = dirt;
			~out = synthBus;
			~globalEffectBus = globalEffectBus;
			~numChannels = dirt.numChannels;
			~server = server;

			// global effects
			~delaytime = -1;
			~delayfeedback = -1;
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

	value { |dirtBus|
		if(test.value, { func.value(dirtBus) })
	}

	== { arg that;
		^this.compareObject(that, #[\name])
	}

	hash {
		^this.instVarHash(#[\name])
	}
}
