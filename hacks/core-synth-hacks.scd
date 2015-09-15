/*

Hacking the core synths is easy, you can live code them here.


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