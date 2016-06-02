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
				this.playSynths;
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
		~hash = ~hash ?? { sound.identityHash };
		buffer = orbit.dirt.getBuffer(sound, ~n);

		if(buffer.notNil) {
			if(buffer.sampleRate.isNil) {
				"Dirt: buffer '%' not yet completely read".format(sound).warn;
				^this
			};
			~instrument = format("dirt_sample_%_%", buffer.numChannels, ~numChannels);
			~buffer = buffer.bufnum;
			~unitDuration = buffer.duration;

		} {
			synthDesc = SynthDescLib.at(sound);
			if(synthDesc.notNil) {
				~instrument = sound;
				~note = ~n;
				~freq = ~freq.value;
				sustainControl = synthDesc.controlDict.at(\sustain);
				~unitDuration = if(sustainControl.isNil) { 1.0 } { sustainControl.defaultValue ? 1.0 }; // use definition, if defined.
			} {
				"no synth or sample named '%' could be found.".format(sound).postln;
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

		var sustain;
		var speed = ~speed;
		var accelerate = ~accelerate;
		var avgSpeed, endSpeed;

		if (~unit == \c) { speed = speed * ~unitDuration * ~cps };

		if(accelerate.isNil) {
			avgSpeed = endSpeed = speed;
		} {
			endSpeed = speed * (1.0 + (accelerate.abs.linexp(0.01, 4, 0.001, 20, nil) * accelerate.sign));
			if(endSpeed.sign != speed.sign) { endSpeed = 0.0 }; // never turn back
			avgSpeed = speed.abs + endSpeed.abs * 0.5;
		};

		if(~unit == \rate) { ~unit = \r }; // API adaption to tidal output


		// sustain is the duration of the sample
		switch(~unit,
			\r, {
				sustain = ~unitDuration * ~length / avgSpeed;
			},
			\c, {
				sustain = ~unitDuration * ~length / avgSpeed;
			},
			\s, {
				sustain = ~length;
			},
			{ Error("this unit ('%') is not defined".format(~unit)).throw };
		);

		~loop !? { sustain = sustain * ~loop.abs };

		if(sustain < orbit.minSustain) {
			^this // drop it.
		};

		~fadeTime = min(orbit.fadeTime, sustain * 0.19098);
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
			3, // add action: addAfter
			~synthGroup, // send to group
			*[
				in: orbit.synthBus, // read from synth bus, which is reused
				out: orbit.dryBus, // write to orbital dry bus
				amp: ~amp,
				cutGroup: ~cut.abs, // ignore negatives here!
				sample: ~hash, // required for the cutgroup mechanism
				sustain: ~sustain, // after sustain, free all synths and group
				fadeInTime: ~fadeInTime, // fade in
				fadeTime: ~fadeTime // fade out
			].asOSCArgArray // append all other args
		)
	}

	prepareSynthGroup {
		~synthGroup = ~server.nextNodeID;
		~server.sendMsg(\g_new, ~synthGroup, 1, orbit.group);
	}

	playSynths {
		var diverted, server = ~server;
		var latency = ~latency + ~lag + (~offset * ~speed);

		~amp = pow(~gain, 4) * orbit.amp;
		~channel !? { ~pan = ~pan + (~channel / ~numChannels) };

		server.makeBundle(latency, { // use this to build a bundle

			~delayAmp = ~delay ? 0.0; // for clarity

			orbit.globalEffects.do { |x| x.set(currentEnvironment) };

			if(~cut != 0) {
				server.sendMsg(\n_set, orbit.group, \gateCutGroup, ~cut, \gateSample, ~hash);
			};

			this.prepareSynthGroup;
			modules.do(_.value(this));
			this.sendGateSynth; // this one needs to be last


		});

	}

	getMsgFunc { |instrument|
		var desc = SynthDescLib.global.at(instrument.asSymbol);
		^if(desc.notNil) { desc.msgFunc }
	}


}

