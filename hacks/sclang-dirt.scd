

(
var dirt = ~dirt;
Event.addEventType(\dirt, {
	~latency = s.latency;
	dirt.orbits.wrapAt(~which ? 0).value(currentEnvironment)
});
)

(
(type:\dirt, which:0, sound: \hh).play;
(type:\dirt, which:1, sound: \hh).play;
)



(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\sound, Pseq([\bd, \hh, \bd, \hh], inf),
		\vowel, Pshuf([\a, \i, \o, \i, \u], inf),
		\resonance, Pwhite(0.0, 1.0),
		\shape, Pseq([1, -4, 3, 0, 0], inf),
		\dur, 0.25 * Pseq([1, 1/2, 1], inf)
	)
).play
)

(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\sound, \hh,
		\index, Pseries(),
		\dur, 0.25 * Pseq([1, 1/2, 1], inf)
	)
).play
)


(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\sound, Pseq([\bd, \hh, \bd, \hh], inf),
		\index, Pseries(),
		\dur, 0.25 * Pseq([1, 1/2, 1], inf)
	)
).play
)


