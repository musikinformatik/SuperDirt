/*

SuperCollider implementation of Dirt

This object handles OSC communication and local effects.
These are relative to a server and a number of output channels
It keeps a number of dirt orbits (see below).

(C) 2015-2020 Julian Rohrhuber and contributors

SuperDirt is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

SuperDirt {

	var <numChannels, <server;
	var <soundLibrary, <vowels;
	var <>orbits;
	var <>modules;
	var <>audioRoutingBusses;
	var <>controlBusses;
	var <group;
	var <flotsam;

	var <port, <senderAddr, <replyAddr, netResponders;
	var <>receiveAction, <>warnOutOfOrbit = true, <>maxLatency = 42;
	var <>dropWhen = false;
	var <>numRoutingBusses = 16, <>numControlBusses = 128;

	classvar <>default, <>maxSampleNumChannels = 2, <>postBadValues = false;

	*new { |numChannels = 2, server|
		^super.newCopyArgs(numChannels, server ? Server.default).init
	}

	*resetEverything {
		"===========> stopping all servers and recompiling the class library.".postln;
		Server.killAll;
		thisProcess.recompile;
	}

	init {
		soundLibrary = DirtSoundLibrary(server, numChannels);
		modules = [];
		this.loadSynthDefs;
		this.initVowels(\counterTenor);
		this.initRoutingBusses;
		group = server.nextPermNodeID;
		flotsam = IdentityDictionary.new;
	}


	start { |port = 57120, outBusses, senderAddr = (NetAddr("127.0.0.1"))|
		if(orbits.notNil) { this.stop };
		this.makeOrbits(outBusses ? [0]);
		this.connect(senderAddr, port)
	}

	stop {
		orbits.do(_.free);
		orbits = nil;
		this.clearFlotsam;
		this.closeNetworkConnection;
	}

	makeOrbits { |outBusses|
		var new, i0 = if(orbits.isNil) { 0 } { orbits.lastIndex };
		new = outBusses.asArray.collect { |bus, i| DirtOrbit(this, bus, i + i0) };
		orbits = orbits ++ new;
		^new.unbubble
	}

	initRoutingBusses {
		audioRoutingBusses = { Bus.audio(server, numChannels) }.dup(numRoutingBusses);
		controlBusses = { Bus.control(server, 1) }.dup(numControlBusses);
	}

	set { |...pairs|
		orbits.do(_.set(*pairs))
	}

	setControlBus { |...pairs|
		pairs.pairsDo { |index, value|
			var bus = controlBusses.at(index);
			if(bus.notNil) { bus.set(value) }
		};
	}

	free {
		soundLibrary.free;
		audioRoutingBusses.do(_.free);
		this.stop;
	}

	/* analysis */

	startSendRMS { |rmsReplyRate = 20, rmsPeakLag = 3|
		orbits.do(_.startSendRMS(rmsReplyRate, rmsPeakLag))
	}

	stopSendRMS {
		orbits.do(_.stopSendRMS)
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

	loadSoundFileFolder { |folderPath, name, appendToExisting = false, sortFiles = true|
		soundLibrary.loadSoundFileFolder(folderPath, name, appendToExisting, sortFiles)
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

	doNotReadYet_ { |bool|
		soundLibrary.doNotReadYet_(bool)
	}

	doNotReadYet {
		^soundLibrary.doNotReadYet
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

	clearFlotsam {
		flotsam.clear
	}

	// parameter names are prefixed by an &

	handshakeReplyData {
		var data = List.new;
		data.add("&serverHostname");
		data.add(server.addr.hostname);
		data.add("&serverPort");
		data.add(server.addr.port);
		data.add("&controlBusIndices");
		controlBusses.do { |x| data.add(x.index) };
		^data
	}

	connect { |argSenderAddr, argPort|

		var playFunc;



		if(Main.scVersionMajor == 3 and: { Main.scVersionMinor == 6 }) {
			"Please note: SC3.6 listens to any sender.".warn;
			senderAddr = nil;
		} {
			if (argSenderAddr.ip == "0.0.0.0") {
				senderAddr = nil;
			} {
				senderAddr = argSenderAddr;
			};
		};

		port = argPort;

		this.closeNetworkConnection;


		playFunc = { |msg, time, tidalAddr|
			var latency = time - thisThread.seconds;
			var event = (), orbit, index;
			if(dropWhen.value.not) {
				if(latency > maxLatency) {
					"The scheduling delay is too long. Your networks clocks may not be in sync".warn;
					latency = 0.2;
				};
				replyAddr = tidalAddr; // collect tidal reply address
				event[\latency] = latency;
				event[\timeStamp] = time;
				event.putPairs(msg[1..]);
				receiveAction.value(event);
				index = event[\orbit] ? 0;

				if(warnOutOfOrbit and: { index >= orbits.size } or: { index < 0 }) {
					"SuperDirt: event falls out of existing orbits, index (%)".format(index).warn
				};

				DirtEvent(orbits @@ index, modules, event).play
			}
		};

		netResponders.add(
			OSCFunc({ |msg, time, tidalAddr|
				var name = msg[1].asSymbol;
				var synth = SynthDescLib.global.at(name);
				var controls = synth.controls;
				var controlNames = msg[1];
				controls.do{|control| controlNames = controlNames ++ " " ++ control.name};
				tidalAddr.sendMsg("/dirt/synth-info/reply", controlNames);
			}, "/dirt/synth-info", senderAddr, recvPort: port).fix
		);

		netResponders.add(
			OSCFunc({ |msg, time, tidalAddr|
				replyAddr = tidalAddr; // collect tidal reply address
				replyAddr.sendMsg("/dirt/hello/reply");
			}, "/dirt/hello", senderAddr, recvPort: port).fix
		);

		netResponders.add(
			OSCFunc({ |msg, time, tidalAddr|
				tidalAddr.sendMsg("/dirt/handshake/reply", *this.handshakeReplyData)
			}, "/dirt/handshake", senderAddr, recvPort: port).fix
		);

		netResponders.add(
			// pairs of parameter names and values in arbitrary order
			OSCFunc(playFunc, "/dirt/play", senderAddr, recvPort: port).fix
		);

		netResponders.add(
			OSCFunc({ |msg, time, tidalAddr|
				var args = msg.drop(1);
				this.setControlBus(*args);
			}, "dirt/setControlBus", senderAddr, recvPort: port).fix
		);
		netResponders.add(
			OSCFunc({ |msg|
				var nodeID = msg[1];
				flotsam.removeAt(nodeID);
			}, "/n_end", server.addr, recvPort: NetAddr.langPort).fix
		);

		CmdPeriod.add(this);

		// backward compatibility

		netResponders.add(
			// pairs of parameter names and values in arbitrary order
			OSCFunc(playFunc, '/play2', senderAddr, recvPort: port).fix
		);



		"SuperDirt: listening on port %".format(port).postln;
	}

	cmdPeriod {
		this.clearFlotsam
	}

	closeNetworkConnection {
		netResponders.do { |x| x.free };
		netResponders = List.new;
		replyAddr = nil;
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
		^keys.collect { |x| format("% = pF \"%\"", x, x, x) }.join("\n    ");
	}

	*predefinedSynthParameters {
		// not complete, but avoids obvious collisions
		^#[\pan, \amp, \out, \i_out, \sustain, \gate, \accelerate, \gain, \overgain, \unit, \cut, \octave, \offset, \attack];
	}


}
