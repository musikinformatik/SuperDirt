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
		dirtBusses = [ports, outBusses, senderAddrs].flop.collect(DirtBus(this, *_))
	}

	stop {
		dirtBusses.do(_.free);
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

	clearModules {
		modules = [];
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

	// SynthDefs are signal processing graph definitions
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
	var <group, <globalEffects, netResponders;
	var <>releaseTime = 0.02;

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
		if(args.first.isKindOf(Symbol).not) { "wrong tidal format, please set 'namedParams = True'".warn; ^this };
		DirtEvent(this, dirt.modules, args).play
	}

	openNetworkConnection {

		this.closeNetworkConnection;

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
			}, '/play', senderAddr, recvPort: port).fix
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

			// values from the dirt bus
			~dirtBus = this;
			~dirt = dirt;
			~synthBus = synthBus;
			~outBus = outBus;
			~globalEffectBus = globalEffectBus;
			~numChannels = dirt.numChannels;
			~server = server;

			// more defaults:
			~latency = 0.0;
			~length = 1.0;
			~sustain = 1.0;
			~bufferDuration = 1.0;

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
