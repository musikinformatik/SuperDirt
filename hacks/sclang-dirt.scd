
SuperDirt.default = ~dirt;

// test, can you hear
(
(type:\dirt, orbit:0, s: \cr).play;
(type:\dirt, orbit:1, s: \cr, speed:2/5).play;
)



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


(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\s, Pwrand([\hh, \cr], [0.99, 0.01], inf),
		\n, Pseq([Prand([1, Pseq([1, 0, 5], 1), Pseq([0, 0])], 1), 0, 0, 0, 0, 0, 0, 0, 0], inf),
		\speed, Pseq([1, 1, 0.5, 1.2], inf),
		\dur, 0.25 * Pseq([1/2], inf),
		\room, Pseq([0, 0, 0.4], inf)
	)
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



// vowel tennis
(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\speed, 2,
		\sound, Pseq([\bd, \hh, \bd, \hh], inf),
		\vowel, Pshuf([\a, \i, \o, \i, \u], inf),
		\resonance, 0.5,
		\shape, Pseq([1, -4, 3, 0, 0], inf),
		\dur, 0.25 * Pseq([1, 1/2, 1], inf)
	)
).play
)

