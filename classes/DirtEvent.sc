DirtEvent {

	var <orbit, <modules, <event;
	var server, messages;

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
				this.calcTimeSpan;
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
		var soundEvent;
		~hash = ~hash ?? { ~s.identityHash };
		soundEvent = orbit.dirt.soundLibrary.getEvent(~s, ~n);
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
		~length = abs(~end - ~begin);
	}

	calcTimeSpan {

		var sustain, unitDuration; // fixme unitDuration
		var speed = ~speed;
		var accelerate = ~accelerate;
		var avgSpeed, endSpeed;

		unitDuration = ~unitDuration ? ~delta;

		if (~unit == \c) { speed = speed * unitDuration * ~cps };

		if(accelerate.isNil) {
			endSpeed = speed;
			avgSpeed = speed.abs;
		} {
			endSpeed = speed * (1.0 + accelerate);
			avgSpeed = speed.abs + endSpeed.abs * 0.5;
		};

		if(~unit == \rate) { ~unit = \r }; // API adaption to tidal output

		// sustain is the duration of the sample
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
		);

		~loop !? { unitDuration = unitDuration * ~loop.abs };
		sustain = ~sustain ?? { if(~legato.notNil) { ~delta * ~legato } { unitDuration } };

		// let samples end if needed
		~buffer !? { sustain = min(unitDuration, sustain) };

		~fadeTime = min(~fadeTime, sustain * 0.19098);
		~fadeInTime = if(~begin != 0) { ~fadeTime } { 0.0 };
		~sustain = sustain - (~fadeTime + ~fadeInTime);
		~speed = speed;
		~endSpeed = endSpeed;

	}

	finaliseParameters {
		~amp = pow(~gain, 4) * ~amp;
		~channel !? { ~pan = ~pan + (~channel / ~numChannels) };
		~pan = ~pan * 2 - 1; // convert unipolar (0..1) range into bipolar one (-1...1)
		~note = ~note ? ~n;
		~freq = ~freq.value;
		~delayAmp = ~delay ? 0.0; // for clarity
		~latency + ~lag + (~offset * ~speed);
	}

	getMsgFunc { |instrument|
		var desc = SynthDescLib.global.at(instrument.asSymbol);
		^if(desc.notNil) { desc.msgFunc }
	}

	prepareMessage {
		messages = Array.new(32);
	}

	sendSynth { |instrument, args|
		var group = ~synthGroup;
		args = args ?? { this.getMsgFunc(instrument).valueEnvir };
		messages = messages.add(
			[\s_new,
				instrument,
				-1, // no id
				1, // add action: addToTail
				group, // send to group
			] ++ args
		)
	}

	addMsg { |msg|
		messages = messages.add(msg)
	}

	prepareSynthGroup { |outerGroup|
		~synthGroup = server.nextNodeID;
		server.sendMsg(\g_new, ~synthGroup, 1, outerGroup ? orbit.group);
	}

	playSynths {
		var cutGroup;

		this.prepareMessage;


		server.makeBundle(~latency, { // use this to build a bundle

			if(~cut != 0) { cutGroup = orbit.getCutGroup(~cut) };
			orbit.globalEffects.do { |x| x.set(currentEnvironment) };

			if(cutGroup.notNil) {
				server.sendMsg(\n_set, cutGroup, \gateSample, ~hash, \cutAll, if(~cut > 0) { 1 } { 0 });
			};

			this.prepareSynthGroup(cutGroup);

			modules.do(_.value(this));
			this.addMessagesToBundle;
		});

	}

	// this first multichannel expands (flops) each synth message
	// and then all of them together
	addMessagesToBundle {
		messages.collect { |x|
			x.asControlInput.flop
		}.flop.do { |msgs|
			server.listSendBundle(nil, msgs.collect(_.asOSCArgArray))
		}
	}


}

