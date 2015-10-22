

(
var db = ~d1;
Event.addEventType(\dirt, {
	db.value(currentEnvironment)
});
)


(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\sound, Pseq([\bd, \hh, \bd, \hh], inf),
		\vowel, Pshuf("aeiou", inf),
		\dur, 0.25 * Pseq([1, 1/2, 1], inf)
	)
).play
)
