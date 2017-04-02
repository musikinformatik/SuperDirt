DirtEvent {

	var <orbit, <modules, <event;

	*new { |orbit, modules, event|
		^super.newCopyArgs(orbit, modules).init(event)
	}

	init { |argEvent|
		event = argEvent.parent_(orbit.defaultParentEvent);
	}

	play {
		event.use {
			// s and n stand for synth/sample and note/number
			~s ?? { this.splitName };
			// unless diversion returns something, we proceed as usual
			~diversion.value ?? {
				this.getBuffer;
				this.orderRange;
				this.calcRange;
				if(~sustain >= orbit.minSustain) { this.playSynths }; // otherwise drop it.
			}
		}
	}

	splitName {
		var s, n;
		#s, n = ~sound.asString.split($:);
		~s = s.asSymbol;
		~n = if(n.notNil) { n.asFloat } { 0.0 };
	}


	getBuffer {
		var buffer, sound, synthDesc, sustainControl;
		sound = ~s;
		buffer = orbit.dirt.getBuffer(sound, ~n);

		if(buffer.notNil) {
			if(buffer.sampleRate.isNil) {
				"Dirt: buffer '%' not yet completely read".format(sound).warn;
				^this
			};
			~instrument = format("dirt_sample_%_%", buffer.numChannels, ~numChannels);
			~buffer = buffer.bufnum;
			~unitDuration = buffer.duration;
			~hash = ~hash ?? { buffer.identityHash };

		} {
			synthDesc = SynthDescLib.at(sound);
			if(synthDesc.notNil) {
				~instrument = sound;
				~note = ~note ? ~n;
				~freq = ~freq.value;
				~unitDuration = ~delta;
				~hash = ~hash ?? { sound.identityHash };
				//sustainControl =  synthDesc.controlDict.at(\sustain);
				//if(sustainControl.isNil) { ~delta } { sustainControl.defaultValue ? ~delta }
			} {
				~notFound.value
			}
		}
	}

	orderRange {
		var temp;
		if(~end >= ~begin) {
			if(~speed < 0) { temp = ~end; ~end = ~begin; ~begin = temp };
		} {
			// backwards
			~speed = ~speed.neg;
		};
		~length = abs(~end - ~begin);
	}

	calcRange {

		var sustain, unitDuration;
		var speed = ~speed;
		var accelerate = ~accelerate;
		var avgSpeed, endSpeed;

		if (~unit == \c) { speed = speed * ~unitDuration * ~cps };

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
				unitDuration = ~unitDuration * ~length / avgSpeed;
			},
			\c, {
				unitDuration = ~unitDuration * ~length / avgSpeed;
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

	sendSynth { |instrument, args|
		args = args ?? { this.getMsgFunc(instrument).valueEnvir };
		~server.sendMsg(\s_new,
			instrument,
			-1, // no id
			1, // add action: addToTail
			~synthGroup, // send to group
			*args.asOSCArgArray // append all other args
		)
	}

	sendGateSynth {
		~server.sendMsg(\s_new,
			"dirt_gate" ++ ~numChannels,
			-1, // no id
			1, // add action: addToTail
			~synthGroup, // send to group
			*[
				in: orbit.synthBus, // read from synth bus, which is reused
				out: orbit.dryBus, // write to orbital dry bus
				amp: ~amp,
				sample: ~hash, // required for the cutgroup mechanism
				sustain: ~sustain, // after sustain, free all synths and group
				fadeInTime: ~fadeInTime, // fade in
				fadeTime: ~fadeTime // fade out
			].asOSCArgArray // append all other args
		)
	}

	prepareSynthGroup { |outerGroup|
		~synthGroup = ~server.nextNodeID;
		~server.sendMsg(\g_new, ~synthGroup, 1, outerGroup ? orbit.group);
	}

	playSynths {
		var diverted, server = ~server;
		var latency = ~latency + ~lag + (~offset * ~speed);
		var cutGroup;

		~amp = pow(~gain, 4) * ~amp;
		~channel !? { ~pan = ~pan + (~channel / ~numChannels) };
		~pan = ~pan * 2 - 1; // convert unipolar (0..1) range into bipolar one (-1...1)
		if(~cut != 0) { cutGroup = orbit.getCutGroup(~cut) };

		server.makeBundle(latency, { // use this to build a bundle

			~delayAmp = ~delay ? 0.0; // for clarity

			orbit.globalEffects.do { |x| x.set(currentEnvironment) };

			if(cutGroup.notNil) {
				server.sendMsg(\n_set, cutGroup, \gateSample, ~hash, \cutAll, if(~cut > 0) { 1 } { 0 });
			};

			this.prepareSynthGroup(cutGroup);
			modules.do(_.value(this));
			this.sendGateSynth; // this one needs to be last


		});

	}

	getMsgFunc { |instrument|
		var desc = SynthDescLib.global.at(instrument.asSymbol);
		^if(desc.notNil) { desc.msgFunc }
	}


}

