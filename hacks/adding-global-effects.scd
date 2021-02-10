// these are the global effects on each orbit
~dirt.orbits.do { |x| x.globalEffects.postln }

// say you want to add a global low pass filter

// first you generate the synth defs for it
(
var numChannels = ~dirt.numChannels;
(1..SuperDirt.maxSampleNumChannels).do { |numChannels|
	SynthDef("dirt_global_lpf" ++ numChannels, { |dryBus, effectBus, gate = 1, cutoffFreq = 440|
		var signal = In.ar(dryBus, numChannels);

		var rq;
		signal = signal.asArray.collect { |sig|
			rq = 1/LFNoise2.kr(0.1).exprange(10, 20);
			RLPF.ar(sig, cutoffFreq, rq).tanh;
		};
		signal = signal * EnvGen.kr(Env.asr, gate, doneAction:2);
		DirtPause.ar(signal.sum, graceTime:4);

		Out.ar(effectBus, signal)
	}, [\ir, \ir]).add;
};
)


// then add the effect to the orbits
(
~dirt.orbits.do { |x|
	x.globalEffects = x.globalEffects
		.addFirst(GlobalDirtEffect(\dirt_global_lpf, [\cutoffFreq]))

	x.initNodeTree;
};
)

~dirt.orbits.do { |x| x.globalEffects.postln; " ----------".postln; }

// then play some tidal pattern ...
// in tidal

cps (40/120)

let cutoffFreq = pF "cutoffFreq"

d1 $ sound "[sn [sn sn]][sn [sn sn*3]][sn [sn*5 sn]][bd bd]" # cutoffFreq "220 880"
