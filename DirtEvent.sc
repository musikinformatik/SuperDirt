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
			this.getBuffer;
			this.orderRange;
			this.calcRange;
			this.playSynths;
		}
	}


	getBuffer {
		var buffer;
		buffer = dirtBus.dirt.getBuffer(~sound);

		if(buffer.notNil) {
			if(buffer.sampleRate.isNil) {
				"Dirt: buffer '%' not yet completely read".format(~sound).warn;
				^this
			};
			~numFrames = buffer.numFrames;
			~bufferDuration = buffer.duration;
			~sampleRate = buffer.sampleRate;
			~sample = ~sound.identityHash;
			~buffer = buffer.bufnum;
			~instrument = format("dirt_sample_%_%", buffer.numChannels, ~numChannels);

		} {
			if(SynthDescLib.at(~sound).notNil) {
				~instrument = ~sound;
				~sampleRate = ~server.sampleRate;
				~numFrames = ~sampleRate; // assume one second
				~bufferDuration = 1.0;
			} {
				"Dirt: no sample or instrument found for '%'.\n".postf(~sound);
			}
		}
	}

	orderRange {
		var temp;
		if(~end >= ~start) {
			if(~speed < 0) { temp = ~end; ~end = ~start; ~start = temp };
			~length = ~end - ~start;
		} {
			// backwards
			~length = ~start - ~end;
			~speed = ~speed.neg;
		}
	}

	calcRange {
		var sustain;
		if(~unit == \rate) { ~unit = \r }; // API adaption to tidal output

		// sustain is the duration of the sample
		switch(~unit,
			\r, {
				sustain = ~bufferDuration * ~length / ~speed;
				~startFrame = ~numFrames * ~start;
				~endFrame = ~numFrames * ~end;
			},
			\c, {
				sustain = ~length / ~cps;
				~speed = ~speed * ~cps;
				~startFrame = ~numFrames * ~start;
				~endFrame = ~numFrames * ~end;
			},
			\s, {
				sustain = ~length;
				~startFrame = ~sampleRate * ~start;
				~endFrame = ~sampleRate * ~end;
			},
			{ Error("this unit ('%') is not defined".format(~unit)).throw };
		);

		//unit.postln;
		//[\end_start, ~endFrame - ~startFrame / sampleRate, \sustain, sustain].postln;

		if(~accelerate != 0) {
			// assumes linear acceleration
			~sustain = sustain + (~accelerate * sustain * 0.5 * ~speed.sign.neg);
		} {
			~sustain = sustain
		}

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
				in: ~synthBus,  // read from private
				out: ~outBus,     // write to outBus,
				globalEffectBus: ~globalEffectBus,
				effectAmp: ~delay,
				amp: ~amp,
				cutGroup: ~cutgroup.abs, // ignore negatives here!
				sample: ~sample, // required for the cutgroup mechanism
				sustain: ~sustain, // after sustain, free all synths and group
				release: dirtBus.releaseTime // fade out
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
		var latency = ~latency + ~server.latency;

		~amp = pow(~gain, 4) * 0.1;

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

