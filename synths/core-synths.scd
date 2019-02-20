/*

EVENT - BASED
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

		SynthDef(name, { |out, bufnum, sustain = 1, begin = 0, end = 1, speed = 1, endSpeed = 1, freq = 440, pan = 0|

			var sound, rate, phase, sawrate, numFrames;

			// playback speed
			rate = Line.kr(speed, endSpeed, sustain) * (freq / 60.midicps);

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
		signal = RHPF.ar(signal, hcutoff.abs, hresonance.linexp(0, 1, 1, 0.001));
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
		shape = min(shape, 1.0 - 4e-10); // avoid division by zero
		//amp = 1.0 - (0.15 * shape / (shape + 2.0)) * amp; // optional gain comp
		shape = (2.0 * shape) / (1.0 - shape);

		signal = (1 + shape) * signal / (1 + (shape * abs(signal)));
		ReplaceOut.ar(out, signal * amp)
	}, [\ir, \ir]).add;

	SynthDef("dirt_lpf" ++ numChannels, { |out, cutoff = 440, resonance = 0|
		var signal = In.ar(out, numChannels);
		signal = RLPF.ar(signal, cutoff.abs, resonance.linexp(0, 1, 1, 0.001));
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir, \ir]).add;

	SynthDef("dirt_envelope" ++ numChannels, { |out, attack = 0, hold = 0, release = inf |
		var signal = In.ar(out, numChannels);
		signal = signal * EnvGen.ar(Env.linen(attack, hold, release, 1, -3));
		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \ir, \ir]).add;

	SynthDef("dirt_pitch_shift" ++ numChannels, { |out, psratio = 1, sustain = 1|
		var signal = In.ar(out, numChannels);
		var windowSize = sustain.linlin(0.01, 0.3, 0.01, 0.18);
		windowSize.poll(0, "windowSize");
		signal = PitchShift.ar(signal, windowSize:windowSize, pitchRatio:psratio, pitchDispersion:0, timeDispersion:0);
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir, \ir]).add;

	SynthDef("dirt_tremolo" ++ numChannels, { |out, tremolorate = 1.0, tremolodepth = 0.5 |
		var signal, tremolowave;

		tremolodepth = tremolodepth.clip(0, 1) * 0.5;
		tremolowave = (1 - tremolodepth) + SinOsc.ar(tremolorate, 0.5pi, tremolodepth);

		signal = In.ar(out, numChannels);
		signal = signal * tremolowave;

		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \ir]).add;

	// Phaser audio DSP effect definition. Params: phaserrate (Hz); phaserdepth (amplitude)
	SynthDef("dirt_phaser" ++ numChannels, { |out, phaserrate = 1.0, phaserdepth = 0.5, sustain = 4 |
		var signal, phaserwave;
		var phase =  LFPar.kr(phaserrate).range(0.0088, 0.01);

		phaserdepth = phaserdepth.clip(0, 1);

		signal = In.ar(out, numChannels);

		phaserwave = AllpassL.ar(signal, sustain, phase, 0, phaserdepth);

		signal = signal + phaserwave;

		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \ir]).add;

}.value
)

