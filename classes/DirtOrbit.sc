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

	var <dirt,  <outBus, <orbitIndex;
	var <server;
	var <synthBus, <globalEffectBus, <dryBus;
	var <group, <globalEffects;
	var <>minSustain;


	var <>defaultParentEvent;

	*new { |dirt, outBus, orbitIndex = 0|
		^super.newCopyArgs(dirt, outBus, orbitIndex).init
	}

	init {
		server = dirt.server;
		if(server.serverRunning.not) {
			Error("SuperCollider server '%' not running. Couldn't start DirtOrbit".format(server.name)).warn;
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
		CmdPeriod.add(this);
	}

	initDefaultGlobalEffects {
		this.globalEffects = [
			// all global effects sleep when the input is quiet for long enough and no parameters are set.
			GlobalDirtEffect(\dirt_delay, [\delaytime, \delayfeedback, \delaySend, \delayAmp, \lock, \cps]),
			GlobalDirtEffect(\dirt_reverb, [\size, \room, \dry]),
			GlobalDirtEffect(\dirt_leslie, [\leslie, \lrate, \lsize]),
			GlobalDirtEffect(\dirt_rms, [\rmsReplyRate, \rmsPeakLag]).alwaysRun_(true).active_(false),
			GlobalDirtEffect(\dirt_monitor, [\limitertype]).alwaysRun_(true),
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

	}

	initNodeTree {
		server.makeBundle(nil, { // make sure they are in order
			server.sendMsg("/g_new", dirt.group, 0, 1); // make sure group exists
			server.sendMsg("/g_new", group, 0, dirt.group); // make sure group exists
			globalEffects.reverseDo { |x|
				x.play(group, outBus, dryBus, globalEffectBus, orbitIndex)
			}
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

	setGlobalEffects { |...pairs|
		var event = ().putPairs(pairs);
		globalEffects.do { |x| x.set(event) };
	}

	getGlobalEffect { |name|
		var effect = globalEffects.detect { |x| x.name == name };
		if(effect.isNil) {
			Error("No global effect with this name: '%'".format(name)).throw;
		};
		^effect
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

	startSendRMS { |rmsReplyRate = 8, rmsPeakLag = 3|
		this.getGlobalEffect(\dirt_rms).set((rmsReplyRate: rmsReplyRate, rmsPeakLag: rmsPeakLag)).active_(true);
		this.initNodeTree; // we need this because the reply rate can't be modulated
	}

	stopSendRMS {
		this.getGlobalEffect(\dirt_rms).active_(false)
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
			~gain = 1.0;
			~overgain = 0.0;
			~cut = 0.0;
			~unit = \r;
			~n = \none; // sample number or note
			~octave = 5;
			~midinote = #{ ~note ? ~n + (~octave * 12) };
			~freq = #{ ~midinote.value.midicps };
			~dur = 1.0;
			~delta = #{ ~dur.value };

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
