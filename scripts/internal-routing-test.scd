




// modulated band limited impulse
(
SynthDef(\impin, { |out, modfreq = 1, rq = 0.1, pan|
	var sound;
	sound = \input.ar(0 ! ~dirt.numChannels);
	sound = sound.sum; // mix it down to mono
	sound = RLPF.ar(sound, LFTri.kr(modfreq).exprange(200, 14000), rq);
	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan)
	)
}).add
);


SuperDirt.default = ~dirt;

~dirt.audioRoutingBusses // here are the busses
~dirt.audioRoutingBusses.size // 16, so you can use numbers from 0-15
~dirt.audioRoutingBusses.at(7).scope;


(
Pdef(\x,
	Ppar([
		Pbind(
			\type, \dirt,
			\s, \cr, // play a crash
			\to, 7, // map it to bus number 7
			\pan, 0,
			\dur, 1/Pseq([1, 3, 2, 1], inf)
		),

		Pbind(
			\type, \dirt,
			\s, \impin,
			\from, 7, // read audio from bus number 7
			\toArg, \input, // map the audio to the "input" argument (see synthdef above)
			\modfreq, Pseq([2, Prand([3, 7], 1), 0.3, 0.4], inf),
			\rq, Pwhite().linexp(0, 1, 0.05, 0.3),
			\dur, 1, //1/Pseq([1, 3, 2, 1], inf),
			\legato, 2,
			\pan, 0, //Pseq([0, 1], inf)
		)
	])
).stop.play
)



(
(type: \dirt, s: \cr, pan: 1.0.rand2, speed: 0.8, to: 0, psst:1).play;
(type: \dirt, s: \impin, from: 0, toArg: \input, modfreq: exprand(1, 15)).play;
)

