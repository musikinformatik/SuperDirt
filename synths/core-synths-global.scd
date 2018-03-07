/*

ORBIT BASED (GLOBAL)
CORE SYNTHDEFS FOR DIRT
(REQUIRED: GlobalDirtEffects)

	Global synth defs: these synths run in each DirtOrbit and are only released when it is stopped
	when you change them, to update them, hit cmd-period (i.e. stop the synths on the server) once.
	they'll come back automatically

*/



(
{
	var numChannels = ~dirt.numChannels;


	/*

	Routing and Analysis

	*/

	SynthDef("dirt_monitor" ++ numChannels, { |dryBus, effectBus, outBus, gate = 1|
		var drySignal = In.ar(dryBus, numChannels);
		var wetSignal = In.ar(effectBus, numChannels);
		//var signal = XFade2.ar(wetSignal, drySignal, dry * 2 - 1);
		var signal = wetSignal + drySignal;
		var post = if(SuperDirt.postBadValues) { 2 } { 0 };

		signal = Select.ar(CheckBadValues.ar(signal, post: post) > 0, [signal, DC.ar(0)]);

		signal = Limiter.ar(signal);

		// or if you like it harsher
		//signal = tanh(signal);
		// or:
		//signal = distort(signal);

		DirtPause.ar(signal, graceTime:4);

		signal = signal * EnvGen.kr(Env.asr, gate, doneAction:2);
		Out.ar(outBus, signal)
	}, [\ir, \ir, \kr, \kr]).add;


	// RMS measurement, sending back to editor
	SynthDef("dirt_rms" ++ numChannels, { |gate = 1, dryBus, effectBus, rmsReplyRate, rmsPeakLag, orbitIndex|
		var drySignal = In.ar(dryBus, numChannels);
		var wetSignal = In.ar(effectBus, numChannels);
		var signal = wetSignal + drySignal;

		DirtPause.ar(signal, graceTime:4);
		EnvGen.kr(Env.asr, gate, doneAction:2);

		SendPeakRMS.kr(signal, replyRate: rmsReplyRate, peakLag: rmsPeakLag, cmdName:"/rms", replyID: orbitIndex)

	}, [\kr, \ir, \ir, \kr, \kr, \kr]).add;



	/*

	Effect synths

	Each must have at least: dryBus, effectBus, gate

	dryBus and effectBus have \ir as rates (they shouldn't change at runtime)

	*/



	if(\SwitchDelay.asClass.notNil) {

		SynthDef("dirt_delay" ++ numChannels, { |dryBus, effectBus, gate = 1, delaytime, delayfeedback, delaySend = 1, delayAmp = 1, lock = 0, cps = 1|
			var signal;
			var input = In.ar(dryBus, numChannels);
			var maxDelayTime = 4;

			input = input * delaySend.lag(LFNoise1.kr(1).range(0.01, 0.02)); // regulate input

			delayfeedback = delayfeedback.max(0);
			delaytime = delaytime * if(lock, reciprocal(cps), 1);
			delaytime = delaytime.clip(0, maxDelayTime); // just to be sure
			// from sc3-plugins
			signal = \SwitchDelay.asClass.ar(input, 1, 1, delaytime, delayfeedback, maxDelayTime);

			DetectSilence.ar(signal, time:1, doneAction: 1);
			// doesn't work properly. We don't really know when it's not used anymore.
			// this would have to be an explicit signal from sclang

			signal = signal * EnvGen.kr(Env.asr, gate, doneAction:2);
			signal = signal * delayAmp.lag(0.01);

			DirtPause.ar(signal, graceTime:4);

			Out.ar(effectBus, signal);

		}, [\ir, \ir]).add;
	} {
		"\n\n ---- SC3-Plugins not found. This is not a problem."
		"Note that we are using a comb delay, which may not sound the same as SwitchDelay from the plugins".postln;

		SynthDef("dirt_delay" ++ numChannels, { |dryBus, effectBus, gate = 1, delaytime, delayfeedback, delayAmp = 1, lock = 0, cps = 1|
			var signal = In.ar(dryBus, numChannels);
			var maxDelayTime = 4;
			var decayTime;

			delayfeedback = delayfeedback.clip(0, 0.99);
			delaytime = delaytime * if(lock, reciprocal(cps), 1);
			delaytime = delaytime.clip(0, maxDelayTime); // just to be sure
			decayTime = log2(-60.dbamp) / log2(delayfeedback) * delaytime;
			decayTime = decayTime.clip(0, 20);

			signal = CombL.ar(signal, maxDelayTime, delaytime.lag(1), decayTime);

			signal = LeakDC.ar(signal) * delayAmp.lag(0.01) * EnvGen.kr(Env.asr, gate, doneAction:2);

			DirtPause.ar(signal, graceTime:4);

			Out.ar(effectBus, signal);
		}, [\ir, \ir]).add;
	};


	// thanks to Jost Muxfeld and James McCartney
	// note that "size" is not room size, just the feed level into the room

	SynthDef("dirt_reverb" ++ numChannels, { |dryBus, effectBus, gate = 1, room = 0, size = 0.1, dry = 0|
		var in, snd, loop, depth;

		in = In.ar(dryBus, numChannels).asArray.sum;

		in = in * room.lag(LFNoise1.kr(1).range(0.01, 0.02)); // regulate input

		4.do { in = AllpassN.ar(in, 0.03, { Rand(0.005, 0.02) }.dup(numChannels), 1) };

		depth = size.lag(0.02).linexp(0, 1, 0.01, 0.98); // change depth between 0.1 and 0.98
		loop = LocalIn.ar(numChannels) * { depth + Rand(0, 0.05) }.dup(numChannels);
		loop = OnePole.ar(loop, 0.5);  // 0-1

		loop = AllpassN.ar(loop, 0.05, { Rand(0.01, 0.05) }.dup(numChannels), 2);

		loop = DelayN.ar(loop, 0.3, [0.19, 0.26] + { Rand(-0.003, 0.003) }.dup(2));
		loop = AllpassN.ar(loop, 0.05, { Rand(0.03, 0.15) }.dup(numChannels), 2);

		loop = loop + in;
		loop = LeakDC.ar(loop);

		LocalOut.ar(loop);

		snd = loop;
		snd = snd * (1 - dry).lag(LFNoise1.kr(1).range(0.01, 0.02));

		DirtPause.ar(snd, graceTime:4);

		snd = snd * EnvGen.kr(Env.asr, gate, doneAction:2);

		Out.ar(effectBus, snd);

	}, [\ir, \ir]).add;


	// "leslie" controls dry/wet
	// "lrate" is the modulation rate (typical vintage rates would be 6.7 for "fast", 0.7 for "slow")
	// "lsize" is the physical size of the cabinet in meters, this mostly affects the Doppler amount (pitch warble)

	SynthDef("dirt_leslie" ++ numChannels, { |dryBus, effectBus, gate = 1, leslie=0.5, lrate=6.7, lsize=0.3|
		var in, distance, throb, sound1, sound2, bal1, bal2, snd;

		in = In.ar(dryBus, numChannels);
		ReplaceOut.ar(dryBus, in * (1 - leslie));

		if(numChannels > 2) { in = in.clump(2).sum };
		distance = SinOsc.ar(Lag.kr(lrate,10), 0).range(0, lsize);
		throb = SinOsc.ar(Lag.kr(lrate*0.8, 20), 0).range(0,lsize*1.3);
		bal1 = SinOsc.kr(Lag.kr(lrate*0.8, 4), pi/2).range(-0.2,0.2);
		bal2 = SinOsc.kr(Lag.kr(lrate,2), pi/2).range(-0.4, 0.4);
		sound2 = HPF.ar(in, 800);
		sound1 = in - sound2;
		sound1 = leslie * (1.0 - throb) * sound1;
		sound1 = Balance2.ar(sound1[0], sound1[1], bal1);
		sound2 = DelayC.ar(sound2, 1, distance / 343);
		sound2 = leslie * (1.0 - distance) * sound2;
		sound2 = Balance2.ar(sound2[0], sound2[1], bal2);

		snd = 1.2 * (sound1 + sound2);

		DirtPause.ar(snd, graceTime:4);
		snd = snd * EnvGen.kr(Env.asr, gate, doneAction:2);

		case(
			{ numChannels == 1 }, { snd = snd.sum },
			{ numChannels > 2 }, {
				snd = [
					// wild interpretation
					PanAz.ar(numChannels, snd[0], LFSaw.kr(lrate)),
					PanAz.ar(numChannels, snd[1], LFSaw.kr(lrate) + 1)
				].sum
			}
		);


		Out.ar(effectBus, snd);

	}, [\ir, \ir]).add;

	"---- core synth defs loaded ----".postln;

}.value
);
