
// these are the global effects on each orbit
~dirt.orbits.do { |x| x.globalEffects.postln }

// say you want to add a global low pass filter on the first orbit

// first you generate the synth defs for it
(
(1..SuperDirt.maxSampleNumChannels).do { |numChannels|
	SynthDef("dirt_global_lpf" ++ numChannels, { |out, effectBus, gate = 1|
		var signal = In.ar(effectBus, numChannels).asArray.sum;
		signal = signal * EnvGen.kr(Env.asr, gate, doneAction:2);
		signal = RLPF.ar(signal, LFNoise2.kr(LFNoise1.kr(0.1).exprange(0.05, 1)).exprange(60, 13000), 0.1);
		ReplaceOut.ar(out, signal)
	}).add;
};
)


// then add the effect to the orbit
(
~dirt.orbits[0].globalEffects = ~dirt.orbits[0].globalEffects.addFirst(
	GlobalDirtEffect(\dirt_global_lpf, [\server]) // keep it always on by using a parameter that is always present
);
~dirt.orbits[0].initNodeTree;
)

~dirt.orbits.do { |x| x.globalEffects.postln }

// then play some tidal pattern ...

