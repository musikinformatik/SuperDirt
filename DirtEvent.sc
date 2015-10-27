DirtEvent {

	var dirtBus, modules, event;

	*new { |dirtBus, modules, args|
		^super.newCopyArgs(dirtBus, modules).init(args)
	}


	init { |args|
		event = ().putPairs(args).parent_(dirtBus.defaultParentEvent);
	}

	play {
		event.use {
			this.splitName;
			this.getBuffer;
			this.orderRange;
			this.calcRange;
			this.playSynths;
		}
	}

	splitName {
		var key, index;
		#key, index = ~sound.asString.split($:);
		~key = key.asSymbol;
		~index = if(index.isNil) { 0.0 } { index.asFloat };
	}


	getBuffer {
		var buffer, synthDesc, sustainControl;
		buffer = dirtBus.dirt.getBuffer(~key, ~index);

		if(buffer.notNil) {
			if(buffer.sampleRate.isNil) {
				"Dirt: buffer '%' not yet completely read".format(~sound).warn;
				^this
			};
			~instrument = format("dirt_sample_%_%", buffer.numChannels, ~numChannels);
			~sample = ~sound.identityHash;
			~buffer = buffer.bufnum;
			~unitDuration = buffer.duration;

		} {
			synthDesc = SynthDescLib.at(~key);
			if(synthDesc.notNil) {
				~instrument = ~key;
				sustainControl = synthDesc.controlDict.at(\sustain);
				~unitDuration = if(sustainControl.isNil) { 1.0 } { sustainControl.defaultValue ? 1.0 }; // use definition, if defined.
			} {
				"Dirt: no sample or instrument found for '%'.\n".postf(~sound);
			}
		}
	}

	orderRange {
		var temp;
		if(~end >= ~start) {
			if(~speed < 0) { temp = ~end; ~end = ~start; ~start = temp };
		} {
			// backwards
			~speed = ~speed.neg;
		};
		~length = abs(~end - ~start);
	}

	calcRange {

		var sustain, avgSpeed;
		var speed = ~speed;
		var accelerate = ~accelerate;
		var endSpeed;

		if (~unit == \c) { speed = speed * ~unitDuration * ~cps };

		endSpeed = speed * (1.0 + (accelerate.abs.linexp(0.01, 4, 0.001, 20, nil) * accelerate.sign));
		if(endSpeed.sign != speed.sign) { endSpeed = 0.0 }; // never turn back
		avgSpeed = speed.abs + endSpeed.abs * 0.5;

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

		if(sustain < dirtBus.minSustain) {
			^this // drop it.
		};

		~fadeTime = min(dirtBus.fadeTime, sustain * 0.19098);
		~sustain = sustain - (2 * ~fadeTime);
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

	playMonitor {
		~server.sendMsg(\s_new,
			"dirt_monitor" ++ ~numChannels,
			-1, // no id
			3, // add action: addAfter
			~synthGroup, // send to group
			*[
				in: ~out,  // read from private
				out: dirtBus.outBus,     // write to outBus,
				globalEffectBus: ~globalEffectBus,
				effectAmp: ~delay,
				amp: ~amp,
				cutGroup: ~cutgroup.abs, // ignore negatives here!
				sample: ~sample, // required for the cutgroup mechanism
				sustain: ~sustain, // after sustain, free all synths and group
				fadeTime: ~fadeTime // fade in and out
			].asOSCArgArray // append all other args
		)
	}

	updateGlobalEffects {
		if(~delaytime > 0 or: { ~delayfeedback > 0 }) {
			~server.sendMsg(\n_set, dirtBus.globalEffects[\dirt_delay].nodeID,
				\delaytime, ~delaytime,
				\delayfeedback, ~delayfeedback
			)
		}
	}

	prepareSynthGroup {
		~synthGroup = ~server.nextNodeID;
		~server.sendMsg(\g_new, ~synthGroup, 1, dirtBus.group);
	}

	playSynths {
		var server = ~server;
		var latency = ~latency + (~offset * ~speed); // ~server.latency +

		~amp = pow(~gain, 4) * dirtBus.amp;

		server.makeBundle(latency, { // use this to build a bundle

			this.updateGlobalEffects;

			if(~cutgroup != 0) {
				server.sendMsg(\n_set, dirtBus.group, \gateCutGroup, ~cutgroup, \gateSample, ~sample);
			};

			this.prepareSynthGroup;
			modules.do(_.value(this));
			this.playMonitor; // this one needs to be last


		});

	}

	getMsgFunc { |instrument|
		var desc = SynthDescLib.global.at(instrument.asSymbol);
		^if(desc.notNil) { desc.msgFunc }
	}


}

