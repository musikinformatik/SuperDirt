

(
var db = ~d1;
Event.addEventType(\dirt, { |server|
	~latency = ~latency ? server.latency;
	db.performWithEnvir(\value, currentEnvironment)
});
)


(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\sound, Pseq([\bd, \hh, \bd, \hh], inf),
		\vowel, Pshuf([\a, \i, \o, \i, \u], inf),
		\dur, 0.25 * Pseq([1, 1/2, 1], inf)
	)
).play
)
