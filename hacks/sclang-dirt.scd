
SuperDirt.default = ~dirt;

// test, can you hear
(
(type:\dirt, orbit:0, s: \cr).play;
(type:\dirt, orbit:1, s: \cr, speed:2/5).play;
)


// some hihats
(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\s, \hh,
		\n, Pseq([1, 0, 0, 0, 0], inf),
		\speed, Pseq([1, 1, 0.5, 1.2], inf),
		\dur, 0.25 * Pseq([1, 1/2, 1, 2, 2, 1/2], inf),
		\room, Pseq([0, 0, 0.4], inf)
	)
).play
)

// take any, not five
(
var names = ~dirt.soundLibrary.bufferEvents.keys;
var clumps = names.asArray.scramble.curdle(0.1);
Pdef(\x,
	Pbind(
		\type, \dirt,
		\s, Pn(Plazy {
			var n = clumps.choose;
			postln(join(n, " ") ++ "\n");
			Pfuncn({ n.choose }, 2 ** rrand(6, 9))
		}),
		\n, Pwhite(0, 20, inf),
		\speed, Pbrown(1, 1.2, 0.01),
		\amp, Pwhite().linexp(0, 1, 0.001, 0.3),
		\legato, 2,
		\dur, 1 / 32 * Pshuf([1, 1/2, 1, 2, 2, 1/2], inf),
		\room, Pwrand([0, 0.8], [0.9, 0.1], inf),
	)
);
Pdef(\y, Ppar([Pdef(\x), Pdef(\x)])).play
)


(
Pdef(\x,
	Ppar([
		Pbind(
			\type, \dirt,
			\s, Pwrand([\hh, \cr, \ho], [2, 1, 1].normalizeSum, inf),
			\cut, Prand([0, 1, 2], inf),
			\n, Pseq([Prand([1, Pseq([1, 0, 5], 1), Pseq([0, 0])], 1), 0, 0, 0, 0, 0, 0, 0, 0], inf),
			\speed, Pseq([1, 1, 0.5, 1.2], inf),
			\dur, 0.25 * Pseq([1/2, 1/3, 2/3], inf),
			\room, Pseq([0, 0, 0.4], inf)
		),
		Pbind(
			\type, \dirt,
			\s, \bd,
			\dur, Pseq([0.5, 0.25, 0.25], inf),
			\amp, Prand([0.5, 0], inf)
		)
	])
).play
)


(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\s, \hh,
		\n, Pseq([1, 0, 0, 0, 0], inf),
		\speed, Pseq([1, 1, 0.5, 1.2], inf),
		\dur, 0.25 * Pseq([1, 1/2, Prand([1, 1/2], 1), 2, 2, 1/2], inf),
		\cutoff, Pseg(Pwhite().linexp(0, 1, 300, 10000), 3, \lin, inf),
		\resonance, 0.3,
		\room, Pseq([0, 0, 0.4, 1], inf)
	)
).play
)




(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\s, \hh,
		\n, Pseries(),
		\dur, 0.25 * Pseq([1, 1/2, 1], inf)
	)
).play
)


(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\s, Pseq([\bd, \hh, \bd, \hh], inf),
		\n, Pseries(),
		\dur, 0.25 * Pseq([1, 1/2, 1], inf)
	)
).play
)


// multichannel expand effects
(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\s, Pseq([\bd, \hh, \bd, \hh], inf),
		\dur, 0.25 * Pseq([1, 1/2, 1], inf),
		\cutoff, [1345, 1000, 400] + Prand([0, 0, 0, 0, 0, 0, -100, 200, [-100, 210]], inf),
		\resonance, 0.8
	)

).play
)



// vowel tennis
(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\speed, 2,
		\sound, Pseq([\bd, \hh, \bd, \hh], inf),
		\vowel, Pn(Plazy {Pshuf([\a, \i, \o, \i, \u, [\i, \a], [\o, \u, \e]], rrand(3, 8)) }),
		\resonance, 0.7,
		\shape, Pseq([0.5, 0.8, 0.3, 0.2, 0.2], inf),
		\dur, 0.25 * Pseq([1, 1/2, 1], inf)
	)
).play
)

