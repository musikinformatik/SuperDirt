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

		SynthDef(name, { |out, bufnum, sustain = 1, begin, speed = 1, endSpeed = 1, pan = 0|

			var sound, rate, phase;

			// playback speed
			rate = Line.kr(speed, endSpeed, sustain);

			// sample phase
			// BufSampleRate adjusts the rate if the sound file doesn't have the same rate as the soundcard
			phase =  Sweep.ar(1, rate * BufSampleRate.ir(bufnum)) + (BufFrames.ir(bufnum) * begin);

			sound = BufRd.ar(
				numChannels: sampleNumChannels,
				bufnum: bufnum,
				phase: phase,
				loop: 0, // should we loop?
				interpolation: 4 // cubic interpolation
			);

			sound = DirtPan.ar(sound, numChannels, pan, mix:false);

			Out.ar(out, sound)
		}, [\ir, \ir, \ir, \ir, \ir, \ir, \ir, \ir]).add;
	};

	/*

	Bus Routing Monitor

	*/


	// the monitor does the mixing and zeroing of the busses for each sample grain
	// so that they can all play in one bus

	SynthDef("dirt_monitor" ++ numChannels, { |out, in, globalEffectBus, effectAmp = 0, sustain = 1, fadeTime = 0.001, amp = 1|
		var signal = In.ar(in, numChannels);
		 //  doneAction: 3: free node before, which is the group with sample player and effects
		var env = EnvGen.ar(Env([0, 1, 1, 0], [fadeTime, sustain, fadeTime], \sin), doneAction: 3);
		signal = signal * amp * env * DirtGateCutGroup.ar(sustain, fadeTime, doneAction: 3);
		OffsetOut.ar(out, signal);
		OffsetOut.ar(globalEffectBus, signal * effectAmp);
		ReplaceOut.ar(in, Silent.ar(numChannels)) // clears bus signal for subsequent synths
	}, [\ir, \ir, \ir, \ir, \ir, \ir, \ir]).add;



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
		signal = signal.round(0.5 ** crush);
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
		bandq = max(0.1, bandq);  // limit quality, avoid division by zero
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




	// global synth defs: these synths run in each DirtBus and are only released when it is stopped
	// when you change them, to update them, hit cmd-period (i.e. stop the synths on the server) once.
	// they'll come back automatically

	if(\SwitchDelay.asClass.notNil) {


		SynthDef("dirt_delay" ++ numChannels, { |out, effectBus, gate = 1, delaytime, delayfeedback|
			var signal = In.ar(effectBus, numChannels);

			// from sc3-plugins
			signal = SwitchDelay.ar(signal, 1, 1, delaytime, delayfeedback);

			signal = signal * EnvGen.kr(Env.asr, gate, doneAction:2);
			Out.ar(out, signal);

		}, [\ir, \ir, \kr, \kr, \kr]).add;
	} {
		SynthDef("dirt_delay" ++ numChannels, { |out, effectBus, gate = 1, delaytime, delayfeedback|
			var signal = In.ar(effectBus, numChannels);
			var loop = LocalIn.ar(numChannels);

			signal = signal + (loop * delayfeedback.lag(0.3));
			signal = DelayC.ar(signal, 1, 1, delaytime.lag(1));
			LocalOut.ar(signal);

			signal = LeakDC.ar(signal) * EnvGen.kr(Env.asr, gate, doneAction:2);
			Out.ar(out, signal);
		}, [\ir, \ir, \kr, \kr, \kr]).add;
	};

	SynthDef("dirt_limiter" ++ numChannels, { |out, gate = 1|
		var signal = In.ar(out, numChannels);
		signal = signal * EnvGen.kr(Env.asr, gate, doneAction:2);
		signal = Limiter.ar(signal);
		// or if you like it harsher
		//signal = tanh(signal);
		// or:
		//signal = distort(signal);
		ReplaceOut.ar(out, signal)
	}).add;

	// thanks to Jost Muxfeld:

	SynthDef("dirt_reverb" ++ numChannels, { |out, effectBus, gate = 1, amp = 0.1, depth = 0.4|
		var in, snd, loop;

		in = In.ar(effectBus, numChannels).asArray.sum;

		4.do { in = AllpassN.ar(in, 0.03, { Rand(0.005, 0.02) }.dup(numChannels), 1) };


		depth = depth.linlin(0, 1, 0.1, 0.98); // change depth between 0.1 and 0.98
		loop = LocalIn.ar(numChannels) * { depth + Rand(0, 0.05) }.dup(numChannels);
		loop = OnePole.ar(loop, 0.5);  // 0-1

		loop = AllpassN.ar(loop, 0.05, { Rand(0.01, 0.05) }.dup(numChannels), 2);

		loop = DelayN.ar(loop, 0.3, [0.19, 0.26] + { Rand(-0.003, 0.003) }.dup(2));
		loop = AllpassN.ar(loop, 0.05, { Rand(0.03, 0.15) }.dup(numChannels), 2);

		loop = LeakDC.ar(loop);
		loop = loop + in;

		LocalOut.ar(loop);

		snd = Delay2.ar(loop);
		snd = snd * EnvGen.kr(Env.asr, gate, doneAction:2);

		Out.ar(out, snd * amp);

	}, [\ir, \ir, \kr, \kr, \kr]).add;


	"---- core synth defs loaded ----".postln;

}.value
);