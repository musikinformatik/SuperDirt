/*

Hacking the core synths is easy, you can live code them here.


*/

// use with a tidal pattern that uses |+| bandqf or|+| bandq

// start modulating the bandpass filter
(
SynthDef("dirt_bpf" ++ numChannels, { |out, bandqf = 440, bandq = 10|
	var signal = In.ar(out, ~dirt.numChannels);
	bandqf = bandqf * SinOsc.kr(XLine.kr(1, 100, 0.2), Rand(0, 2pi), 0.1, 1);
	signal = BPF.ar(signal, bandqf, 1/bandq) * max(bandq, 1.0);
	ReplaceOut.ar(out, signal)
}, [\ir, \ir, \ir]).add;
)