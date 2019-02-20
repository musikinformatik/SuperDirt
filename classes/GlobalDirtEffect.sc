
/*
this keeps state of running synths that have a livespan of the DirtOrbit
sends only OSC when an update is necessary

"name" is the name of the SynthDef
(for each possible number of channels appended by a number, see: core-synths)
"paramNames" is an array of keys (symbols) which to look up as arguments
"numChannels" is the number of synth channels (no need to specify if you use it in a DirtOrbit)
*/



GlobalDirtEffect {

	var <>name, <>paramNames, <>numChannels, <state;
	var <>alwaysRun = false;
	var synth, defName;

	*new { |name, paramNames, numChannels|
		^super.newCopyArgs(name, paramNames, numChannels, ())
	}

	play { |group, outBus, dryBus, effectBus, orbitIndex|
		this.release;
		synth = Synth.after(group, name.asString ++ numChannels,
			[\outBus, outBus, \dryBus, dryBus, \effectBus, effectBus, \orbitIndex, orbitIndex] ++ state.asPairs
		)
	}

	release { |releaseTime = 0.2|
		if(synth.notNil) {
			synth.server.sendBundle(nil,
				['/error', -1], // surpress error, because we don't keep track of server state
				[12, synth.nodeID, 1], // /n_run: make sure it isn't paused
				[15, synth.nodeID, \gate, -1.0 - releaseTime], // n_set: use gate to set release time
				['/error', -2]
			);
		};
	}

	set { |event|
		var argsChanged, someArgsNotNil = alwaysRun;
		paramNames.do { |key|
			var value = event[key];
			value !? { someArgsNotNil = true };
			if(state[key] != value) {
				argsChanged = argsChanged.add(key).add(value);
				state[key] = value;
			}
		};
		if(someArgsNotNil) { this.resume };
		if(argsChanged.notNil) {
			synth.set(*argsChanged);
		}
	}

	resume {
		synth.run;
		synth.set(\resumed, 1)
	}

	printOn { |stream|
		stream  << this.class.name << "(" <<<* [name, paramNames] << ")"
	}

	storeArgs {
		^[name, paramNames, numChannels]
	}

}
