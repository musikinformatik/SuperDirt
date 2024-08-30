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
			rate = Line.kr(speed, endSpeed, sustain) * (freq / 36.midicps);

			// sample phase
			// BufSampleRate adjusts the rate if the sound file doesn't have the same rate as the soundcard

			numFrames = max(BufFrames.ir(bufnum), 1); // make sure it is > 0, when no file is read yet
			sawrate = rate * BufSampleRate.ir(bufnum) / (absdif(begin, end) * numFrames);
			phase = (speed.sign * LFSaw.ar(sawrate, 1)).range(begin, end) * numFrames;

			//phase =  Sweep.ar(1, rate * BufSampleRate.ir(bufnum)) + (BufFrames.ir(bufnum) * begin);

			sound = BufRd.ar(
				numChannels: sampleNumChannels,
				bufnum: bufnum,
				phase: phase,
				loop: 0,
				interpolation: 4 // cubic interpolation
			);

			sound = DirtPan.ar(sound, numChannels, pan);

			Out.ar(out, sound)
		}, [\ir, \ir, \ir, \ir, \ir, \ir, \ir, \ir, \kr]).add; // pan can be modulated
	};

	// the same for supporting long soundfiles.
	// Direct file indexing is limited by 32bit float phase argument of BufRd
	// but BufRd has cubic interpolation and is more hackable
	// see DirtSoundLibrary > instrumentForBuffer

	(1..SuperDirt.maxSampleNumChannels).do { |sampleNumChannels|

		var name = format("dirt_sample_long_%_%", sampleNumChannels, numChannels);

		SynthDef(name, { |out, bufnum, sustain = 1, begin = 0, end = 1, speed = 1, endSpeed = 1, freq = 440, pan = 0|

			var sound, rate,  env, startPos, numFrames;

			// playback speed
			rate = Line.kr(speed, endSpeed, sustain) * (freq / 60.midicps);

			// sample phase
			// BufSampleRate adjusts the rate if the sound file doesn't have the same rate as the soundcard
			//phase =  Sweep.ar(1, rate * BufSampleRate.ir(bufnum)) + (BufFrames.ir(bufnum) * begin);

			rate = rate * BufRateScale.ir(bufnum);

			numFrames = max(BufFrames.ir(bufnum), 1); // make sure it is > 0, when no file is read yet

			// when we play backward from zero, we have to start from the end
			startPos = if((rate < 0) * (begin <= 0), numFrames, numFrames * begin);

			sound = PlayBuf.ar(
				numChannels: sampleNumChannels,
				bufnum: bufnum,
				rate: rate,
				startPos: startPos,
				loop: 0
			);

			env = EnvGen.kr(Env.linen(0, sustain, 0)); // todo: check if control rate smoothens (shouldn't)

			sound = sound * env;

			sound = DirtPan.ar(sound, numChannels, pan);

			Out.ar(out, sound)
		}, [\ir, \ir, \ir, \ir, \ir, \ir, \ir, \ir, \kr]).add; // pan can be modulated
	};

	// this is the time-stretching sample player, based on an overlap-add method
	// the method is designed for timescale > 1 (i.e. stretching),
	// but works reasonably well for values between 0.1 and 3, depending on the sample
	(1..SuperDirt.maxSampleNumChannels).do { |sampleNumChannels|

		var name = format("dirt_stretchsample_%_%", sampleNumChannels, numChannels);

		SynthDef(name, { |out, bufnum, sustain = 1, begin = 0, end = 1, speed = 1, endSpeed = 1, freq = 440, pan = 0, timescale = 1, timescalewin = 1|

			var sound, rate, phase, sawrate, numFrames, index, windowIndex, window, timescaleStep;
			var sound0, sound1, windowSize, nSteps;

			// playback speed
			rate = Line.kr(speed, endSpeed, sustain) * (freq / 60.midicps);

			// sample phase
			// BufSampleRate adjusts the rate if the sound file doesn't have the same rate as the soundcard
			//phase =  Sweep.ar(1, rate * BufSampleRate.ir(bufnum)) + (BufFrames.ir(bufnum) * begin);

			numFrames = BufFrames.ir(bufnum);
			// Picking the right window size is a tricky thing, something around 2000 samples is usually
			// OK for sounds of moderate length (around 0.5 to several seconds long).
			// But this is also scaled below to be a bit smaller/larger based on desired playback rate.
			// If it's still not good, you can use the "timescalewin" parameter to multiply the window size
			windowSize = timescale.clip(0.1,2) * 0.05 * BufSampleRate.ir(bufnum) * timescalewin;
			// Next is the (pre-scaled) number of samples between indices. Note that while windowSize
			// is clipped, timescaleStep cannot be without the duration of the resulting sound becoming
			// different from timescale * sample_duration.
			// For very small values of timescale, this means it'll "skip" through the sound, only playing
			// a few samples at regular intervals
			// For very large values of timescale, the overlap will be very large, possibly leading to
			// some audible repetition
			timescaleStep = windowSize / timescale;
			sawrate = rate * BufSampleRate.ir(bufnum) / (absdif(begin, end) * timescale * numFrames);
			phase = (speed.sign * LFSaw.ar(sawrate, 1)).range(begin,end) * numFrames * timescale;
			// do the overlap-add by running through a pair of indices, shifting weights with the window function
			nSteps = phase.div(timescaleStep) - [1.0, 0.0];
			index = nSteps * (timescaleStep / timescale - timescaleStep) + phase;
			windowIndex = phase - (nSteps * timescaleStep);
			// Gaussian window, the "50" means it's about 3.5 sigma to the edge of the window
			window = exp(-50 * squared(windowIndex/windowSize - 0.5));

			sound0 = window[0] * BufRd.ar(
				numChannels: sampleNumChannels,
				bufnum: bufnum,
				phase: index[0],
				loop: 0,
				interpolation: 4 // cubic interpolation
			);
			sound1 = window[1] * BufRd.ar(
				numChannels: sampleNumChannels,
				bufnum: bufnum,
				phase: index[1],
				loop: 0,
				interpolation: 4 // cubic interpolation
			);
			sound = (sound0 + sound1) / window.sum;

			sound = DirtPan.ar(sound, numChannels, pan);

			Out.ar(out, sound)
		}, [\ir, \ir, \ir, \ir, \ir, \ir, \ir, \ir, \kr, \ir, \ir]).add;
	};



	/*

	Bus Routing Monitor

	*/


	// the monitor does the mixing and zeroing of the busses for each sample grain
	// so that they can all play in one bus

	SynthDef("dirt_gate" ++ numChannels, { |out, in, sustain = 1, release = 0, fadeInTime = 0.001, fadeTime = 0.001, amp = 1, gain = 1, overgain = 0|
		var signal = In.ar(in, numChannels);
		 //  doneAction: 14: free surrounding group and all nodes
		var env = EnvGen.ar(Env([0, 1, 1, 0], [fadeInTime, sustain + release, fadeTime], \sin), doneAction: 14);
		amp = amp * (gain + overgain);
		signal = signal * env * amp * DirtGateCutGroup.ar(fadeTime, doneAction: 14);
		// this takes the signal and offsets it so it matches precisely onto the sample
		// as scheduled within one block (a synth is always started on the block bondary)
		OffsetOut.ar(out, signal);
		ReplaceOut.ar(in, Silent.ar(numChannels)) // clears bus signal for subsequent synths
	}, [\ir, \ir, \ir, \ir, \ir, \kr, \ir, \ir]).add; // amp can be modulated, gain and overgain can't


	/*

	Internal Signal Routing Synths

	*/

	SynthDef("dirt_out" ++ numChannels, { |out, to, sustain = 1, fadeInTime = 0.001, fadeTime = 0.001, through = 0, amp = 1|
		var signal = In.ar(out, numChannels);
		var env = EnvGen.ar(Env([0, 1, 1, 0], [fadeInTime, sustain, fadeTime], \sin));
		
		Out.ar(to, signal * env * amp);
		ReplaceOut.ar(out, signal * through);
	}, [\ir, \ir, \ir, \ir, \ir, \ir, \kr]).add;  // amp can be modulated

	/*

	Effect SynthDefs
	These per-sample-effects are freed after Monitor envelope has ended

	*/

	// vowels are fix for now for each event
	// TODO: send frequecies from tidal, allow their modulation here

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

	}, [\ir]).add;

	// would be nice to have some more parameters in some cases

	SynthDef("dirt_crush" ++ numChannels, { |out, crush = 4|
		var signal = In.ar(out, numChannels);
		signal = signal.round(0.5 ** (crush-1));
		ReplaceOut.ar(out, signal)
	}, [\ir, \kr]).add;


	SynthDef("dirt_coarse" ++ numChannels, { |out, coarse = 0, bandq = 10|
		var signal = In.ar(out, numChannels);
		signal = Latch.ar(signal, Impulse.ar(SampleRate.ir / coarse));
		ReplaceOut.ar(out, signal)
	}, [\ir, \kr, \kr]).add;

	SynthDef("dirt_hpf" ++ numChannels, { |out, hcutoff = 440, hresonance = 0|
		var signal = In.ar(out, numChannels);
		signal = RHPF.ar(signal, hcutoff.abs.clip(20, SampleRate.ir / 2), hresonance.linexp(0, 1, 1, 0.001));
		ReplaceOut.ar(out, signal)
	}, [\ir, \kr, \kr]).add;

	SynthDef("dirt_bpf" ++ numChannels, { |out, bandqf = 440, bandq = 10|
		var signal = In.ar(out, numChannels);
		bandq = max(1, bandq);  // limit quality, avoid division by zero
		bandqf = bandqf.clip(20, SampleRate.ir / 2); // limit extremes
		signal = BPF.ar(signal, bandqf, 1/bandq) * max(bandq, 1.0);
		ReplaceOut.ar(out, signal)
	}, [\ir, \kr, \kr]).add;

	SynthDef("dirt_shape" ++ numChannels, { |out, shape = 0|
		var signal = In.ar(out, numChannels), amp = 1;
		shape = min(shape, 1.0 - 4e-10); // avoid division by zero
		//amp = 1.0 - (0.15 * shape / (shape + 2.0)) * amp; // optional gain comp
		shape = (2.0 * shape) / (1.0 - shape);

		signal = (1 + shape) * signal / (1 + (shape * abs(signal)));
		ReplaceOut.ar(out, signal * amp)
	}, [\ir, \kr]).add;

	SynthDef("dirt_lpf" ++ numChannels, { |out, cutoff = 440, resonance = 0, attack, hold, decay, envamt = 0, anchor = 0, release, holdtime |
		var signal = In.ar(out, numChannels);
		var cutmax = SampleRate.ir / 2;
		var cutmin = 20;
		var offset = envamt.abs * anchor;

		var envmin = clip(2 ** (offset * -1) * cutoff, cutmin, cutmax); 
		var envmax = clip(2 ** (envamt.abs - offset) * cutoff, cutmin, cutmax);
      
		cutoff =  EnvGen.ar(
		   Env.adsr(
			attackTime: attack, 
			decayTime: decay, 
			releaseTime: release, 
			sustainLevel: hold,
			peakLevel:  envmax - envmin, 
			bias: envmin,
			curve: -4
		   ),
		   gate: Trig.ar(1, holdtime)
	    );

		signal = RLPF.ar(signal, cutoff, resonance.linexp(0, 1, 1, 0.001));
		ReplaceOut.ar(out, signal)
	}, [\ir, \kr, \kr]).add;

	SynthDef("dirt_envelope" ++ numChannels, { |out, attack, decay, hold, holdtime = 0, release, curve | 
		var signal = In.ar(out, numChannels);
        var volenv = EnvGen.ar(
		   Env.adsr(
			attackTime: attack, 
			decayTime: decay, 
			releaseTime: release, 
			sustainLevel: hold,
			peakLevel:  1, 
			curve: curve
		   ),
		   gate: Trig.ar(1, holdtime)
	    );
		signal = signal * volenv;
		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \ir, \ir, \ir]).add;


	SynthDef("dirt_grain_envelope" ++ numChannels, { |out, sustain = 1, tilt = 0.5, plat = 0, curve = -3 |
		var signal = In.ar(out, numChannels);
		var p = plat.clip(0, 1);
		var c = tilt.clip(0, 1);

		var riseAndFall = 1 - p;
		var attack = c * riseAndFall;
		var release = (1 - c) * riseAndFall;
		var hold = p;

		// maybe sine shape is better?
		var env = EnvGen.ar(Env.linen(attack, hold, release, 1, curve), timeScale: sustain);

		signal = signal * env;

		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \ir, \ir, \ir]).add;

	SynthDef("dirt_pitch_shift" ++ numChannels, { |out, psrate = 1, sustain = 1, psdisp = 0|
		var signal = In.ar(out, numChannels);
		var windowSize = sustain.linlin(0.01, 0.3, 0.01, 0.18);
		signal = PitchShift.ar(signal, windowSize:windowSize, pitchRatio:psrate, pitchDispersion:0, timeDispersion:psdisp);
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir, \ir]).add;

	SynthDef("dirt_tremolo" ++ numChannels, { |out, tremolorate = 1.0, tremolodepth = 0.5 |
		var signal, tremolowave;

		tremolodepth = tremolodepth.clip(0, 1) * 0.5;
		tremolowave = (1 - tremolodepth) + SinOsc.ar(tremolorate, 0.5pi, tremolodepth);

		signal = In.ar(out, numChannels);
		signal = signal * tremolowave;

		ReplaceOut.ar(out, signal);
	}, [\ir, \kr, \kr]).add;

	// Phaser audio DSP effect definition. Params: phaserrate (Hz); phaserdepth (amplitude)
	// TODO: fix "sustain" value (this parameter is always the synth event duration!)
	SynthDef("dirt_phaser" ++ numChannels, { |out,  sustain = 4, phaserrate = 1.0, phaserdepth = 0.5 |
		var signal, phaserwave;
		var phase =  LFPar.kr(phaserrate).range(0.0088, 0.01);

		phaserdepth = phaserdepth.clip(0, 1);

		signal = In.ar(out, numChannels);

		phaserwave = AllpassL.ar(signal, sustain, phase, 0, phaserdepth);

		signal = signal + phaserwave;

		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \kr, \kr]).add;

}.value
)

