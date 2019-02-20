DirtEvent {

	var <orbit, <modules, <event;
	var server;

	*new { |orbit, modules, event|
		^super.newCopyArgs(orbit, modules, event)
	}

	play {
		event.parent = orbit.defaultParentEvent;
		event.use {
			// s and n stand for synth/sample and note/number
			~s ?? { this.splitName };
			// unless orbit wide diversion returns something, we proceed
			~diversion.(this) ?? {
				this.mergeSoundEvent;
				server = ~server.value; // as server is used a lot, make lookup more efficient
				this.orderTimeSpan;
				this.calcTimeSpan; // ~sustain is called here
				this.finaliseParameters;
				// unless event diversion returns something, we proceed
				~play.(this) ?? {
					if(~sustain >= orbit.minSustain) { this.playSynths }; // otherwise drop it.
				}
			}
		}
	}

	splitName {
		var s, n;
		#s, n = ~sound.asString.split($:);
		~s = s.asSymbol;
		~n = if(n.notNil) { n.asFloat } { 0.0 };
	}

	mergeSoundEvent {
		var soundEvent = orbit.dirt.soundLibrary.getEvent(~s, ~n);
		if(soundEvent.isNil) {
			// only call ~notFound if no ~diversion is given that anyhow redirects control
			if(~diversion.isNil) { ~notFound.value }
		} {
			// the stored sound event becomes the environment's proto slot, which partly can override its parent
			currentEnvironment.proto = soundEvent
		}
	}

	orderTimeSpan {
		var temp;
		if(~end >= ~begin) {
			if(~speed < 0) { temp = ~end; ~end = ~begin; ~begin = temp };
		} {
			// backwards
			~speed = ~speed.neg;
		};
		~length = absdif(~end, ~begin);
	}

	calcTimeSpan {

		var sustain, unitDuration;
		var speed = ~speed.value;
		var loop = ~loop.value;
		var accelerate = ~accelerate.value;
		var avgSpeed, endSpeed;
		var useUnit;

		~freq = ~freq.value;
		unitDuration = ~unitDuration.value;
		useUnit = unitDuration.notNil;


		if (~unit == \c) {
			speed = speed * ~cps * if(useUnit) { unitDuration  } { 1.0 }
		};

		if(accelerate.isNil) {
			endSpeed = speed;
			avgSpeed = speed.abs;
		} {
			endSpeed = speed * (1.0 + accelerate);
			avgSpeed = speed.abs + endSpeed.abs * 0.5;
		};

		if(useUnit) {
			if(~unit == \rate) { ~unit = \r }; // API adaption to tidal output
			switch(~unit,
				\r, {
					unitDuration = unitDuration * ~length / avgSpeed;
				},
				\c, {
					unitDuration = unitDuration * ~length / avgSpeed;
				},
				\s, {
					unitDuration = ~length;
				},
				{ Error("this unit ('%') is not defined".format(~unit)).throw };
			)
		};

		sustain = ~sustain.value ?? {
			if(~legato.notNil) {
				~delta * ~legato.value
			} {
				unitDuration = unitDuration ? ~delta;
				loop !? { unitDuration = unitDuration * loop.abs };
			}
		};

		// end samples if sustain exceeds buffer duration
		// for every buffer, unitDuration is (and should be) defined.
		~buffer !? { sustain = min(unitDuration, sustain) };

		~fadeTime = min(~fadeTime.value, sustain * 0.19098);
		~fadeInTime = if(~begin != 0) { ~fadeTime } { 0.0 };
		~sustain = sustain - (~fadeTime + ~fadeInTime);
		~speed = speed;
		~endSpeed = endSpeed;

	}

	finaliseParameters {
		~amp = pow(~gain.value, 4) * ~amp.value;
		~channel !? { ~pan = ~pan.value + (~channel.value / ~numChannels) };
		~pan = ~pan * 2 - 1; // convert unipolar (0..1) range into bipolar one (-1...1)
		~delayAmp = ~delay ? 0.0; // for clarity
		~latency = ~latency + ~lag.value + (~offset.value * ~speed.value);
	}

	getMsgFunc { |instrument|
		var desc = SynthDescLib.global.at(instrument.asSymbol);
		^if(desc.notNil) { desc.msgFunc } { ~msgFunc }
	}

	sendSynth { |instrument, args|
		var group = ~synthGroup;
		args = args ?? { this.getMsgFunc(instrument).valueEnvir };
		args.asControlInput.flop.do { |each|
			server.sendMsg(\s_new,
				instrument,
				-1, // no id
				1, // add action: addToTail
				group, // send to group
				*each.asOSCArgArray // append all other args
			)
		}
	}

	sendGateSynth {
		server.sendMsg(\s_new,
			"dirt_gate" ++ ~numChannels,
			-1, // no id
			1, // add action: addToTail
			~synthGroup, // send to group
			*[
				in: orbit.synthBus.index, // read from synth bus, which is reused
				out: orbit.dryBus.index, // write to orbital dry bus
				amp: ~amp,
				sample: ~hash, // required for the cutgroup mechanism
				sustain: ~sustain, // after sustain, free all synths and group
				fadeInTime: ~fadeInTime, // fade in
				fadeTime: ~fadeTime // fade out
			]
		)
	}

	prepareSynthGroup { |outerGroup|
		~synthGroup = server.nextNodeID;
		server.sendMsg(\g_new, ~synthGroup, 1, outerGroup ? orbit.group);
	}

	playSynths {
		var cutGroup;
		~cut = ~cut.value;
		if(~cut != 0) {
			cutGroup = orbit.getCutGroup(~cut);
			~hash ?? { ~hash = ~sound.identityHash }; // just to be safe
		};

		server.makeBundle(~latency, { // use this to build a bundle

			orbit.globalEffects.do { |x| x.set(currentEnvironment) };

			if(cutGroup.notNil) {
				server.sendMsg(\n_set, cutGroup, \gateSample, ~hash, \cutAll, if(~cut > 0) { 1 } { 0 });
			};

			this.prepareSynthGroup(cutGroup);
			modules.do(_.value(this));
			this.sendGateSynth; // this one needs to be last

		});

	}


}

