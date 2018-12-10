// Waveloss
// Divides an audio stream into tiny segments, using the signal's
// zero-crossings as segment boundaries, and discards a fraction of them.

(
SynthDef("waveloss" ++ ~dirt.numChannels, { |out, drop = 1|
  var sig;

  sig = In.ar(out, ~dirt.numChannels);
  sig = WaveLoss.ar(sig, drop, outof: 100, mode: 2);
  ReplaceOut.ar(out, sig)
}).add;

~dirt.addModule('waveloss', { |dirtEvent|
  dirtEvent.sendSynth('waveloss' ++ ~dirt.numChannels,
    [
      drop: ~waveloss,
      out: ~out
    ]
  )
}, { ~waveloss.notNil });

// Squiz
// "reminiscent of some weird mixture of filter, ring-modulator
// and pitch-shifter"

SynthDef("squiz" ++ ~dirt.numChannels, { |out, pitchratio = 1|
  var sig;
  sig = In.ar(out, ~dirt.numChannels);
  sig = Squiz.ar(sig, pitchratio);
  ReplaceOut.ar(out, sig)
}).add;

~dirt.addModule('squiz', { |dirtEvent|
  dirtEvent.sendSynth('squiz' ++ ~dirt.numChannels,
    [
      pitchratio: ~squiz,
      out: ~out
    ]
  )
}, { ~squiz.notNil });

// Frequency shifter
// Total shift is sum of `fshift` (in Hz) and `fshiftnote` times the current note frequency.
// `fshiftphase` allows control over the phase
~dirt.addModule('fshift', {|dirtEvent| dirtEvent.sendSynth("dirt_fshift" ++ ~dirt.numChannels,
	[fshift: ~fshift, fshiftphase: ~fshiftphase, fshiftnote: ~fshiftnote, freq: ~freq, out: ~out])}, {~fshift.notNil});
SynthDef("dirt_fshift"++~dirt.numChannels, {|out, fshift, fshiftphase, fshiftnote, freq|
	var sig = In.ar(out, ~dirt.numChannels);
	var shift = freq*fshiftnote + fshift;
	sig = FreqShift.ar(sig, shift, fshiftphase);
	ReplaceOut.ar(out, sig);
}).add;

// Triode-like distortion, uses only the `triode` parameter
~dirt.addModule('triode', {|dirtEvent| dirtEvent.sendSynth("dirt_triode" ++ ~dirt.numChannels,
	[triode: ~triode, out: ~out])}, {~triode.notNil});
SynthDef("dirt_triode"++~dirt.numChannels, {|out, triode|
	var sig, sc;
	sig = In.ar(out, ~dirt.numChannels);
	sc = triode*10+1e-3;
	sig = (sig * (sig > 0)) + (tanh(sig*sc) / sc * (sig < 0));
	ReplaceOut.ar(out, LeakDC.ar(sig));
}).add;

// Sonic Pi's krush
// modified a bit so krush "0" is the same as dry signal
// uses `krush` and `kcutoff` as paramters
~dirt.addModule('krush', { |dirtEvent| dirtEvent.sendSynth("dirt_krush" ++ ~dirt.numChannels,
			[krush: ~krush, kcutoff: ~kcutoff, out: ~out])}, { ~krush.notNil});
SynthDef("dirt_krush" ++ ~dirt.numChannels, {|out, krush, kcutoff|
	var orig, signal, freq;
	freq = Select.kr(kcutoff > 0, [DC.kr(4000), kcutoff]);
	orig = In.ar(out, ~dirt.numChannels);
	signal = (orig.squared + (krush*orig)) / (orig.squared + (orig.abs * (krush-1.0)) + 1.0);
	signal = RLPF.ar(signal, clip(freq, 20, 10000), 1);
	signal = SelectX.ar(krush*2.0, [orig, signal]);
	ReplaceOut.ar(out, signal);
}).add;

// Sonic Pi's octaver
// uses `octer` for octave harmonics, `octersub` for half-frequency harmonics, and `octersubsub` for
// quarter-frequency harmonics
~dirt.addModule('octer', { |dirtEvent| dirtEvent.sendSynth("dirt_octer" ++ ~dirt.numChannels,
	[octer: ~octer, octersub: ~octersub, octersubsub: ~octersubsub, out: ~out])},
    { ~octer.notNil or: {~octersub.notNil } or: {~octersubsub.notNil}});
SynthDef("dirt_octer" ++ ~dirt.numChannels, {|out, octer, octersub, octersubsub|
	var signal, oct1, oct2, oct3, sub;
	signal = In.ar(out, ~dirt.numChannels);
	oct1 = 2.0 * LeakDC.ar( abs(signal) );
	sub = LPF.ar(signal, 440);
	oct2 = ToggleFF.ar(sub);
	oct3 = ToggleFF.ar(oct2);
	signal = SelectX.ar(octer, [signal, octer*oct1, DC.ar(0)]);
	signal = signal + (octersub * oct2 * sub) + (octersubsub * oct3 * sub);
	ReplaceOut.ar(out, signal);
}).add;

// Ring modulation with `ring` (modulation amount), `ringf` (modulation frequency), and `ringdf` (slide
// in modulation frequency)
~dirt.addModule('ring', { |dirtEvent| dirtEvent.sendSynth("dirt_ring" ++ ~dirt.numChannels,
			[ring: ~ring, ringf: ~ringf, ringdf: ~ringdf, out: ~out])}, { ~ring.notNil});
SynthDef("dirt_ring" ++ ~dirt.numChannels, {|out, ring=0, ringf=0, ringdf|
	var signal, mod;
	signal = In.ar(out, ~dirt.numChannels);
	mod = ring * SinOsc.ar(Clip.kr(XLine.kr(ringf, ringf+ringdf), 20, 20000));
	signal = ring1(signal, mod);
	ReplaceOut.ar(out, signal);
}).add;

// A crunchy distortion with a lot of high harmonics, the only parameter is `distort`
~dirt.addModule('distort', { |dirtEvent| dirtEvent.sendSynth("dirt_distort" ++ ~dirt.numChannels,
			[distort: ~distort, out: ~out])}, { ~distort.notNil});
SynthDef("dirt_distort" ++ ~dirt.numChannels, {|out, distort=0|
	var signal, mod ;
	signal = In.ar(out, ~dirt.numChannels);
	mod = CrossoverDistortion.ar(signal, amp:0.2, smooth:0.01);
	mod = mod + (0.1 * distort * DynKlank.ar(`[[60,61,240,3000+SinOsc.ar(62,mul:100)],nil,[0.1, 0.1, 0.05, 0.01]], signal));
	mod = (mod.cubed * 8).softclip * 0.5;
	mod = SelectX.ar(distort, [signal, mod]);
	ReplaceOut.ar(out, mod);
}).add;
)