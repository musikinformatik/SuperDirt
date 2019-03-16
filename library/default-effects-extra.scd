/*

DEFAULT EFFECTS EXTRA

*/
(
	// Waveloss
	// Divides an audio stream into tiny segments, using the signal's
	// zero-crossings as segment boundaries, and discards a fraction of them.

	~dirt.addModule('waveloss', { |dirtEvent|
		dirtEvent.sendSynth('waveloss' ++ ~dirt.numChannels,
			[
				drop: ~waveloss,
				out: ~out
			]
		)
	}, { ~waveloss.notNil });

	SynthDef("waveloss" ++ ~dirt.numChannels, { |out, drop = 1|
		var sig = In.ar(out, ~dirt.numChannels);
		sig = WaveLoss.ar(sig, drop, outof: 100, mode: 2);
		ReplaceOut.ar(out, sig)
	},[\ir, \ir]).add;

	// Squiz
	// "reminiscent of some weird mixture of filter, ring-modulator
	// and pitch-shifter"
	~dirt.addModule('squiz', { |dirtEvent|
		dirtEvent.sendSynth('squiz' ++ ~dirt.numChannels,
			[
				pitchratio: ~squiz,
				out: ~out
			]
		)
	}, { ~squiz.notNil });

	SynthDef("squiz" ++ ~dirt.numChannels, { |out, pitchratio = 1|
		var sig = In.ar(out, ~dirt.numChannels);
		sig = Squiz.ar(sig, pitchratio);
		ReplaceOut.ar(out, sig)
	}, [\ir, \ir]).add;

	// Frequency shifter
	// Total shift is sum of `fshift` (in Hz) and `fshiftnote` times the current note frequency.
	// `fshiftphase` allows control over the phase
	~dirt.addModule('fshift', { |dirtEvent|
		dirtEvent.sendSynth("dirt_fshift" ++ ~dirt.numChannels,
			[
				fshift: ~fshift,
				fshiftphase: ~fshiftphase,
				fshiftnote: ~fshiftnote,
				freq: ~freq,
				out: ~out
			]
		)
	}, { ~fshift.notNil });

	SynthDef("dirt_fshift" ++ ~dirt.numChannels, { |out, fshift, fshiftphase, fshiftnote, freq|
		var sig = In.ar(out, ~dirt.numChannels);
		var shift = freq * fshiftnote + fshift;
		sig = FreqShift.ar(sig, shift, fshiftphase);
		ReplaceOut.ar(out, sig);
	}, [\ir, \ir, \ir, \ir, \ir]).add;

	// Triode-like distortion, uses only the `triode` parameter
	~dirt.addModule('triode', { |dirtEvent|
		dirtEvent.sendSynth("dirt_triode" ++ ~dirt.numChannels,
			[
				triode: ~triode,
				out: ~out
			]
		)
	}, { ~triode.notNil });

	SynthDef("dirt_triode" ++ ~dirt.numChannels, { |out, triode|
		var sig, sc;
		sig = In.ar(out, ~dirt.numChannels);
		sc = triode * 10 + 1e-3;
		sig = (sig * (sig > 0)) + (tanh(sig * sc) / sc * (sig < 0));
		ReplaceOut.ar(out, LeakDC.ar(sig));
	}, [\ir, \ir]).add;

	// Sonic Pi's krush
	// modified a bit so krush "0" is the same as dry signal
	// uses `krush` and `kcutoff` as paramters
	~dirt.addModule('krush', { |dirtEvent|
		dirtEvent.sendSynth("dirt_krush" ++ ~dirt.numChannels,
			[
				krush: ~krush,
				kcutoff: ~kcutoff,
				out: ~out
			]
		)
	}, { ~krush.notNil });

	SynthDef("dirt_krush" ++ ~dirt.numChannels, { |out, krush, kcutoff|
		var orig, signal, freq;
		freq = Select.kr(kcutoff > 0, [DC.kr(4000), kcutoff]);
		orig = In.ar(out, ~dirt.numChannels);
		signal = (orig.squared + (krush * orig)) / (orig.squared + (orig.abs * (krush-1.0)) + 1.0);
		signal = RLPF.ar(signal, clip(freq, 20, 10000), 1);
		signal = SelectX.ar(krush * 2.0, [orig, signal]);
		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \ir]).add;

	// Sonic Pi's octaver
	// uses `octer` for octave harmonics, `octersub` for half-frequency harmonics, and `octersubsub` for
	// quarter-frequency harmonics
	~dirt.addModule('octer', { |dirtEvent|
		dirtEvent.sendSynth("dirt_octer" ++ ~dirt.numChannels,
			[
				octer: ~octer,
				octersub: ~octersub,
				octersubsub: ~octersubsub,
				out: ~out
			]
		)
	}, { ~octer.notNil or: { ~octersub.notNil } or: { ~octersubsub.notNil }});

	SynthDef("dirt_octer" ++ ~dirt.numChannels, { |out, octer, octersub, octersubsub|
		var signal, oct1, oct2, oct3, sub;
		signal = In.ar(out, ~dirt.numChannels);
		oct1 = 2.0 * LeakDC.ar( abs(signal) );
		sub = LPF.ar(signal, 440);
		oct2 = ToggleFF.ar(sub);
		oct3 = ToggleFF.ar(oct2);
		signal = SelectX.ar(octer, [signal, octer * oct1, DC.ar(0)]);
		signal = signal + (octersub * oct2 * sub) + (octersubsub * oct3 * sub);
		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \ir, \ir]).add;

	// Ring modulation with `ring` (modulation amount), `ringf` (modulation frequency), and `ringdf` (slide
	// in modulation frequency)
	~dirt.addModule('ring', { |dirtEvent|
		dirtEvent.sendSynth("dirt_ring" ++ ~dirt.numChannels,
			[
				ring: ~ring,
				ringf: ~ringf,
				ringdf: ~ringdf,
				out: ~out
			]
		)
	}, { ~ring.notNil });

	SynthDef("dirt_ring" ++ ~dirt.numChannels, { |out, ring = 0, ringf = 0, ringdf|
		var signal, mod;
		signal = In.ar(out, ~dirt.numChannels);
		mod = ring * SinOsc.ar(Clip.kr(XLine.kr(ringf, ringf + ringdf), 20, 20000));
		signal = ring1(signal, mod);
		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \ir, \ir]).add;

	// A crunchy distortion with a lot of high harmonics, the only parameter is `distort`
	~dirt.addModule('distort', { |dirtEvent|
		dirtEvent.sendSynth("dirt_distort" ++ ~dirt.numChannels,
			[
				distort: ~distort,
				out: ~out
			]
		)
	}, { ~distort.notNil });

	SynthDef("dirt_distort" ++ ~dirt.numChannels, { |out, distort = 0|
		var signal, mod;
		signal = In.ar(out, ~dirt.numChannels);
		mod = CrossoverDistortion.ar(signal, amp: 0.2, smooth: 0.01);
		mod = mod + (0.1 * distort * DynKlank.ar(`[[60,61,240,3000 + SinOsc.ar(62,mul: 100)],nil,[0.1, 0.1, 0.05, 0.01]], signal));
		mod = (mod.cubed * 8).softclip * 0.5;
		mod = SelectX.ar(distort, [signal, mod]);
		ReplaceOut.ar(out, mod);
	}, [\ir, \ir]).add;

	// Spectral delay
	~dirt.addModule('spectral-delay', { |dirtEvent|
		dirtEvent.sendSynth('spectral-delay' ++ ~dirt.numChannels,
			// OPTIONAL
			// passing this array of parameters could be left out,
			// but it makes it clear what happens and it is also more
			// effecient to explicitly specify the arguments
			[
				xsdelay: ~xsdelay,
				tsdelay: ~tsdelay,
				out: ~out
			]
		)
	}, { ~tsdelay.notNil or: { ~xsdelay.notNil }});

	SynthDef("spectral-delay" ++ ~dirt.numChannels, { |out, tsdelay = 0.5, xsdelay = 0.5|

		var signal, delayTime, delays, freqs, filtered;
		var size = 16;
		var maxDelayTime = 0.2;
		signal = In.ar(out, ~dirt.numChannels);
		delayTime = tsdelay * maxDelayTime;
		filtered = (1..size).sum { |i|
			var filterFreq = i.linexp(1, size, 40, 17000);
			var sig = BPF.ar(signal, filterFreq, 0.005);
			// the delay pattern is determined from xsdelay by bitwise-and:
			DelayN.ar(sig, maxDelayTime, i & xsdelay * (1 / size) * delayTime )
		};
		signal = signal * 0.2 + (filtered * 4); // this controls wet / dry
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir, \ir]).add;

	// Spectral freeze
	~dirt.addModule('spectral-freeze', { |dirtEvent|
		dirtEvent.sendSynth('spectral-freeze' ++ ~dirt.numChannels,
			[
				freeze: ~freeze,
				out: ~out
			]
		)
	}, { ~freeze.notNil } );

	SynthDef("spectral-freeze" ++ ~dirt.numChannels, { |out, freeze|
		var signal, chain, in;
		signal = In.ar(out, ~dirt.numChannels);
		chain = Array.fill(signal.size, { |i| FFT(LocalBuf(2048), signal[i])});
		signal = IFFT(PV_Freeze(chain, freeze));
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir]).add;

	// Spectral comb
	~dirt.addModule('spectral-comb', { |dirtEvent|
		dirtEvent.sendSynth('spectral-comb' ++ ~dirt.numChannels,
			[
				comb: ~comb,
				out: ~out
			]
		)
	}, { ~comb.notNil });

	SynthDef("spectral-comb" ++ ~dirt.numChannels, { |out, comb|
		var signal, chain, in, clean, teeth = 256;
		signal = In.ar(out, ~dirt.numChannels);
		chain = Array.fill(signal.size, { |i| FFT(LocalBuf(2048), signal[i])});
		signal = IFFT(PV_RectComb(chain, numTeeth: teeth * comb, width: 1-comb));
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir]).add;

	// Spectral smear
	~dirt.addModule('spectral-smear', { |dirtEvent|
		dirtEvent.sendSynth('spectral-smear' ++ ~dirt.numChannels,
			[
				smear: ~smear,
				out: ~out
			]
		)
	}, { ~smear.notNil });

	SynthDef("spectral-smear" ++ ~dirt.numChannels, { |out, smear|
		var signal, chain, in;
		signal = In.ar(out, ~dirt.numChannels);
		chain = Array.fill(signal.size, { |i| FFT(LocalBuf(2048), signal[i])});
		signal = IFFT(PV_MagSmear(chain, bins: smear.linexp(0.0,1.0,1,64)));
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir]).add;

	// Spectral scramble
	~dirt.addModule('spectral-scram', { |dirtEvent|
		dirtEvent.sendSynth('spectral-scram' ++ ~dirt.numChannels,
			[
				scram: ~scram,
				out: ~out
			]
		)
	}, { ~scram.notNil });

	SynthDef("spectral-scram" ++ ~dirt.numChannels, { |out, scram|
		var signal, chain, in, clean, teeth = 256;
		signal = In.ar(out, ~dirt.numChannels);
		clean = signal;
		chain = Array.fill(signal.size, { |i| FFT(LocalBuf(2048), signal[i])});
		signal = IFFT(PV_BinScramble(chain, wipe: scram, width: scram));
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir]).add;

	// Spectral binshift
	~dirt.addModule('spectral-binshift', { |dirtEvent|
		dirtEvent.sendSynth('spectral-binshift' ++ ~dirt.numChannels,
			[
				binshift: ~binshift,
				out: ~out
			]
		)
	}, { ~binshift.notNil });

	SynthDef("spectral-binshift" ++ ~dirt.numChannels, { |out, binshift|
		var signal, chain, in, clean, teeth = 256;
		signal = In.ar(out, ~dirt.numChannels);
		clean = signal;
		chain = Array.fill(signal.size, { |i| FFT(LocalBuf(2048), signal[i])});
		signal = IFFT(PV_BinShift(chain, stretch: binshift.linlin(0.0,1.0,0.01,4.0),
		shift: binshift * 10, interp: 1));
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir]).add;

	// Spectral high pass filter
	~dirt.addModule('spectral-hbrick', { |dirtEvent|
		dirtEvent.sendSynth('spectral-hbrick' ++ ~dirt.numChannels,
			[
				hbrick: ~hbrick,
				out: ~out
			]
		)
	}, { ~hbrick.notNil });

	SynthDef("spectral-hbrick" ++ ~dirt.numChannels, { |out, hbrick|
		var signal, chain, in, clean, teeth = 256;
		signal = In.ar(out, ~dirt.numChannels);
		clean = signal;
		chain = Array.fill(signal.size, { |i| FFT(LocalBuf(2048), signal[i])});
		signal = IFFT(PV_BrickWall(chain, wipe: hbrick * 0.6)); // Signal almost disappears around 0.5 therefore it's scaled a bit
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir]).add;

	// Spectral low pass filter
	~dirt.addModule('spectral-lbrick', { |dirtEvent|
		dirtEvent.sendSynth('spectral-lbrick' ++ ~dirt.numChannels,
			[
				lbrick: ~lbrick,
				out: ~out
			]
		)
	}, { ~lbrick.notNil });

	SynthDef("spectral-lbrick" ++ ~dirt.numChannels, { |out, lbrick|
		var signal, chain, in, clean, teeth = 256;
		signal = In.ar(out, ~dirt.numChannels);
		clean = signal;
		chain = Array.fill(signal.size, { |i| FFT(LocalBuf(2048), signal[i])});
		// lbrick parameter scaled to negative range to activate lopass filter (see ugen help file)
		signal = IFFT(PV_BrickWall(chain, wipe: lbrick.linlin(0.0,1.0,0.0,(-1.0))));
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir]).add;

	// Conformer
	~dirt.addModule('spectral-conformer', { |dirtEvent|
		dirtEvent.sendSynth('spectral-conformer' ++ ~dirt.numChannels,
			[
				real: ~real,
				imag: ~imag,
				out: ~out
			]
		)
	}, { ~real.notNil or: ~imag.notNil });

	SynthDef("spectral-conformer" ++ ~dirt.numChannels, { |out, real = 0.5, imag = 0.5|
		var signal, chain, in, clean, teeth = 256;
		signal = In.ar(out, ~dirt.numChannels);
		clean = signal;
		chain = Array.fill(signal.size, { |i| FFT(LocalBuf(2048), signal[i])});
		signal = IFFT(
				PV_ConformalMap(chain, real.linlin(0.0,1.0,0.01,2.0), imag.linlin(0.00,1.0,0.01,10.0))
			).tanh;
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir, \ir]).add;

	// Enhance
	~dirt.addModule('spectral-enhance', { |dirtEvent|
		dirtEvent.sendSynth('spectral-enhance' ++ ~dirt.numChannels,
			[
				enhance: ~enhance,
				out: ~out
			]
		)
	}, { ~enhance.notNil });

	SynthDef("spectral-enhance" ++ ~dirt.numChannels, { |out, enhance = 0.5|
		var signal, chain, in, clean, teeth = 256;
		signal = In.ar(out, ~dirt.numChannels);
		clean = signal;
		chain = Array.fill(signal.size, { |i| FFT(LocalBuf(2048), signal[i])});
		signal = IFFT(
			PV_SpectralEnhance(chain,
				enhance.linlin(0.0,1.0,1,16),
				enhance.linlin(0.0,1.0,1.0,5.0),
				enhance.linlin(0.0,1.0,0.0,0.99))
			).tanh; // .tanh is used as a crude limiter here beacause sometimes this ugen goes crazy
		ReplaceOut.ar(out, signal)
	}, [\ir, \ir]).add;


	// DJ filter, a low pass filter for the first half of the range, and a high pass for the rest.
	~dirt.addModule('dj-filter', { |dirtEvent|
		dirtEvent.sendSynth('dj-filter' ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			djf: ~djf,
			out: ~out
		]
	)}, { ~djf.notNil});

	SynthDef("dj-filter" ++ ~dirt.numChannels, { |out, djf|
		var signal;
		var lpfCutoffFreq = djf.linexp(0, 0.5, 20, 10000);
		var hpfCutoffFreq = djf.linexp(0.5, 1, 20, 10000);

		signal = In.ar(out, ~dirt.numChannels);

		signal = RHPF.ar(
			RLPF.ar(
				signal,
				lpfCutoffFreq
			),
			hpfCutoffFreq
		);
		ReplaceOut.ar(out, signal)
	}).add;
)
