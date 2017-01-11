
SuperDirt.default = ~dirt;

(
(type:\dirt, orbit:0, sound: \hh).play;
(type:\dirt, orbit:1, sound: \hh).play;
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


/*

// this is how it is done in SuperDirt.initClass


(
var dirt = ~dirt;
Event.addEventType(\dirt, {
	~latency = s.latency;
	~delta = ~stretch.value * ~dur.value;
	dirt.orbits.wrapAt(~orbit ? 0).value(currentEnvironment)
});
)

*/


