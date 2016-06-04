
// add a compressor module
(
~dirt.orbits.do { |x|
	x.globalEffects = [
		GlobalDirtEffect(\dirt_delay, [\delaytime, \delayfeedback, \delayAmp, \lock, \cps]),
		GlobalDirtEffect(\dirt_reverb, [\size, \room, \dry]),
		GlobalDirtEffect(\dirt_compressor),
		GlobalDirtEffect(\dirt_monitor, [\dirtOut])
	]
};
)


// now play with different variants while you listen to tidal:


// a dirty hyperbolic tangens
(
SynthDef("dirt_compressor" ++ ~dirt.numChannels, { |dryBus, effectBus, gate = 1|
	var signal = In.ar(dryBus, ~dirt.numChannels);

	signal = (signal * 5).tanh;
	signal = signal * EnvGen.kr(Env.asr, gate, doneAction:2);
	Out.ar(effectBus, signal);
}, [\ir, \ir]).add;

s.freeAll; // restart all synths
)

// a dirty hyperbolic tangens, randomly drifting
(
SynthDef("dirt_compressor" ++ ~dirt.numChannels, { |dryBus, effectBus, gate = 1|
	var signal = In.ar(dryBus, ~dirt.numChannels);

	signal = (signal * LFDNoise1.kr(0.1).exprange(4, 10)).tanh;
	signal = signal * EnvGen.kr(Env.asr, gate, doneAction:2);
	Out.ar(effectBus, signal);
}, [\ir, \ir]).add;

s.freeAll; // restart all synths
)


// a compressor, adjust the parameters by ear
(
SynthDef("dirt_compressor" ++ ~dirt.numChannels, { |dryBus, effectBus, gate = 1|
	var signal = In.ar(dryBus, ~dirt.numChannels);
	signal = Compander.ar(signal, signal * 4, 0.2,
		slopeBelow: 2,
        slopeAbove: 0.5,
        clampTime: 0.01,
        relaxTime: 0.01
	);
	signal = signal * EnvGen.kr(Env.asr, gate, doneAction:2);
	Out.ar(effectBus, signal);
}, [\ir, \ir]).add;

s.freeAll; // restart all synths
)



