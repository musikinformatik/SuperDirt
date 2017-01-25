/*

CORE SYNTHDEFS FOR DIRT
(REQUIRED: CORE MODULES)

these synthdefs can be hacked at runtime, but they are absolutely necessary for tidal to work correctly.

Their name and parameter names shouldn't be changed. Parameter names can be added though.

live coding them requires that you have your SuperDirt instance in an environment variable called ~dirt.

*/

(
{
	var numChannels = ~dirt.numChannels;



	// write variants for different sample buffer sizes
	(1..SuperDirt.maxSampleNumChannels).do { |sampleNumChannels|

		var name = format("dirt_sample_%_%", sampleNumChannels, numChannels);

		SynthDef(name, { |out, bufnum, sustain = 1, begin=0, end=1, speed = 1, endSpeed = 1, pan = 0|

			var sound, rate, phase, sawrate, numFrames;

			// playback speed
			rate = Line.kr(speed, endSpeed, sustain);

			// sample phase
			// BufSampleRate adjusts the rate if the sound file doesn't have the same rate as the soundcard
			//phase =  Sweep.ar(1, rate * BufSampleRate.ir(bufnum)) + (BufFrames.ir(bufnum) * begin);

			numFrames = BufFrames.ir(bufnum);
			sawrate = rate * BufSampleRate.ir(bufnum) / (absdif(begin, end) * numFrames);
			phase = (speed.sign * LFSaw.ar(sawrate, 1)).range(begin,end) * numFrames;

			sound = BufRd.ar(
				numChannels: sampleNumChannels,
				bufnum: bufnum,
				phase: phase,
				loop: 0,
				interpolation: 4 // cubic interpolation
			);

			sound = DirtPan.ar(sound, numChannels, pan);

			Out.ar(out, sound)
		}, [\ir, \ir, \ir, \ir, \ir, \ir, \ir, \ir]).add;
	};

	/*

	Bus Routing Monitor

	*/


	// the monitor does the mixing and zeroing of the busses for each sample grain
	// so that they can all play in one bus

	SynthDef("dirt_gate" ++ numChannels, { |out, in, sustain = 1, fadeInTime = 0.001, fadeTime = 0.001, amp = 1|
		var signal = In.ar(in, numChannels);
		 //  doneAction: 14: free surrounding group and all nodes
		var env = EnvGen.ar(Env([0, 1, 1, 0], [fadeInTime, sustain, fadeTime], \sin), levelScale: amp, doneAction: 14);
		signal = signal * env * DirtGateCutGroup.ar(fadeTime, doneAction: 14);
		OffsetOut.ar(out, signal);
		ReplaceOut.ar(in, Silent.ar(numChannels)) // clears bus signal for subsequent synths
	}, [\ir, \ir, \ir, \ir, \ir, \ir]).add;



	/*

	Effect SynthDefs
	These per-sample-effects are freed after Monitor envelope has ended

	*/

	SynthDef("dirt_vowel" ++ numChannels, { |out, resonance = 0.5, cutoff = 0|
		var voweled, signal, vowelFreqs, vowelAmps, vowelRqs;
		signal = In.ar(out, numChannels);
		vowelFreqs = \vowelFreqs.ir(1000 ! 5) * cutoff.linexp(0, 1, 1, 2);
		vowelAmps = \vowelAmps.ir(0 ! 5) * resonance.linlin(0, 1, 50, 200);
		vowelRqs = \vowelRqs.ir(0 ! 5) / resonance.linlin(0, 1, 1/10, 1/2);
		vowelFreqs = vowelFreqs.minNyquist; // limit ceiling
		voweled = BPF.ar([signal], vowelFreqs, vowelRqs, vowelAmps).sum;
		//voweled = Formlet.ar(signal, vowelFreqs, 0.005, vowelRqs, vowelAmps).sum;
		signal = XFade2.ar(signal, voweled, resonance.linlin(0, 1, -0.5, 1), 0.25);

		ReplaceOut.ar(out, signal);

	}, [\ir, \ir, \ir]).add;

	// would be nice to have some more parameters in some cases

	SynthDef("dirt_crush" ++ numChannels, { |out, crush = 4|
		var signal = In.ar(out, numChannels);
		signal = signal.round(0.5 ** (crush-1));
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir]).add;


	SynthDef("dirt_coarse" ++ numChannels, { |out, coarse = 0, bandq = 10|
		var signal = In.ar(out, numChannels);
		signal = Latch.ar(signal, Impulse.ar(SampleRate.ir / coarse));
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir, \ir]).add;

	SynthDef("dirt_hpf" ++ numChannels, { |out, hcutoff = 440, hresonance = 0|
		var signal = In.ar(out, numChannels);
		signal = RHPF.ar(signal, hcutoff, hresonance.linexp(0, 1, 1, 0.001));
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir, \ir]).add;

	SynthDef("dirt_bpf" ++ numChannels, { |out, bandqf = 440, bandq = 10|
		var signal = In.ar(out, numChannels);
		bandq = max(1, bandq);  // limit quality, avoid division by zero
		bandqf = max(20, bandqf); // limit lower end, avoid blow up
		signal = BPF.ar(signal, bandqf, 1/bandq) * max(bandq, 1.0);
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir, \ir]).add;

	SynthDef("dirt_shape" ++ numChannels, { |out, shape = 0|
		var signal = In.ar(out, numChannels), amp = 1;
		shape = min(shape, 1.0 - 1e-16); // avoid division by zero
		//amp = 1.0 - (0.15 * shape / (shape + 2.0)) * amp; // optional gain comp
		shape = (2.0 * shape) / (1.0 - shape);

		signal = (1 + shape) * signal / (1 + (shape * abs(signal)));
		ReplaceOut.ar(out, signal * amp)
	}, [\ir, \ir]).add;

	SynthDef("dirt_lpf" ++ numChannels, { |out, cutoff = 440, resonance = 0|
		var signal = In.ar(out, numChannels);
		signal = RLPF.ar(signal, cutoff, resonance.linexp(0, 1, 1, 0.001));
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir, \ir]).add;

	SynthDef("dirt_envelope" ++ numChannels, { |out, attack = 0, hold = 0, release = inf |
		var signal = In.ar(out, numChannels);
		signal = signal * EnvGen.ar(Env.linen(attack, hold, release, 1, -3));
		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \ir, \ir]).add;

	SynthDef("dirt_tremolo" ++ numChannels, { |out, tremolorate = 1.0, tremolodepth = 0.5 |
		var signal, tremolowave;

		tremolodepth = tremolodepth.clip(0, 1) * 0.5;
		tremolowave = (1 - tremolodepth) + SinOsc.ar(tremolorate, 0.5pi, tremolodepth);

		signal = In.ar(out, numChannels);
		signal = signal * tremolowave;

		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \ir]).add;


	/*

	 Global synth defs: these synths run in each DirtOrbit and are only released when it is stopped
	 when you change them, to update them, hit cmd-period (i.e. stop the synths on the server) once.
	 they'll come back automatically

	*/

	if(\SwitchDelay.asClass.notNil) {

		SynthDef("dirt_delay" ++ numChannels, { |dryBus, effectBus, gate = 1, delaytime, delayfeedback, delayAmp = 1, lock = 0, cps = 1|
			var signal;
			var input = In.ar(dryBus, numChannels);
			var maxDelayTime = 4;

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

	SynthDef("dirt_monitor" ++ numChannels, { |dryBus, effectBus, outBus, gate = 1|
		var drySignal = In.ar(dryBus, numChannels);
		var wetSignal = In.ar(effectBus, numChannels);
		//var signal = XFade2.ar(wetSignal, drySignal, dry * 2 - 1);
		var signal = wetSignal + drySignal;

		signal = Limiter.ar(signal);

		// or if you like it harsher
		//signal = tanh(signal);
		// or:
		//signal = distort(signal);

		signal = signal * EnvGen.kr(Env.asr, gate, doneAction:2);
		Out.ar(outBus, signal)
	}, [\ir, \ir, \kr, \kr]).add;

	// thanks to Jost Muxfeld and James McCartney
	// note that "size" is not room size, just a depth metaphor

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
	SynthDef("dirt_leslie" ++ numChannels, { |dryBus, effectBus, gate = 1, leslie=0, lrate=6.7, lsize=0.3|
		var in, distance, throb, sound1, sound2, bal1, bal2, snd;

		in = In.ar(dryBus, numChannels);
		ReplaceOut.ar(dryBus, in*(1-leslie));
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

		Out.ar(effectBus, snd);

	}, [\ir, \ir]).add;

	// Tremolo audio DSP effect definition. Params: tremolorate (Hz); tremolodepth (amplitude)
	SynthDef("tremolo" ++ numChannels, { |out, tremolorate = 1.0, tremolodepth = 0.5 |
		var signal, tremolowave;

		tremolorate = tremolorate.clip(0, 10);
		tremolodepth = tremolodepth.clip(0, 1) * 0.5;

		tremolowave = (1 - tremolodepth) + SinOsc.ar(tremolorate, 0.5pi, tremolodepth);

		signal = In.ar(out, numChannels);
		signal = signal * tremolowave;

		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \ir]).add;

	"---- core synth defs loaded ----".postln;

}.value
);
