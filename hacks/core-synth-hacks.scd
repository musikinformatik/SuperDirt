/*

Hacking the core synths is easy, you can live code them here.
This assumes you have stored dirt in a variable ~dirt

*/

/*
use with a tidal pattern that uses |+| bandqf or|+| bandq
e.g.
d1 $ sound "[sn bd sn*2 bd, cy drum:1, drum:2]" |+| bandf "1500 1332 881" |+| bandq "80"
*/

// start modulating the bandpass filter
(
SynthDef("dirt_bpf" ++ ~dirt.numChannels, { |out, bandqf = 440, bandq = 10|
	var signal = In.ar(out, ~dirt.numChannels);
	bandqf = bandqf * SinOsc.kr(XLine.kr(1, 30, Rand(0.2, 0.3)), Rand(0, 2pi), 0.1, 1);
	bandq = max(bandq, 1.0);
	signal = BPF.ar(signal, bandqf, 1/bandq) * bandq;
	ReplaceOut.ar(out, signal)
}, [\ir, \ir, \ir]).add;
)

// make it a chord and cursor position dependent
(
SynthDef("dirt_bpf" ++ ~dirt.numChannels, { |out, bandqf = 440, bandq = 10|
	var signal = In.ar(out, ~dirt.numChannels);
	var freq = bandqf * SinOsc.kr(XLine.kr(1, 30, Rand(0.2, 0.3)), Rand(0, 2pi), 0.1, 1);
	freq = freq * MouseY.kr(0.5, (1, 1.1 ..1.5), 1) ** MouseX.kr(0.5, 1.2);
	freq = max(freq, 1.0);
	signal = BPF.ar(signal, freq, 1/bandq).sum * bandq;
	ReplaceOut.ar(out, signal)
}, [\ir, \ir, \ir]).add;
)

// depend on a continuous node proxy
(
Ndef(\mod, {
	var x;
	x = SinOsc.kr(0.4, 0, 0.1, 1);
	x = x * SinOsc.kr(0.34 * (1..3)).range(0.5, (1, 1.1 ..1.5)) ** SinOsc.kr(0.32).range(0.5, 1.2);
});

SynthDef("dirt_bpf" ++ ~dirt.numChannels, { |out, bandqf = 440, bandq = 10|
	var signal = In.ar(out, ~dirt.numChannels);
	var freq = bandqf * Ndef.ar(\mod);
	freq = max(freq, 1.0);
	signal = BPF.ar(signal, freq, 1/bandq).sum * bandq;
	ReplaceOut.ar(out, signal)
}, [\ir, \ir, \ir]).add;
)