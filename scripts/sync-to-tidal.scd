
// this is a bit experimental:
// sync supercollider to tidal's next incoming beat
// tidal should only send on the first beat


(
var synced = false;
~d1.set(\diversion, {
	if(~s == \sync) {
		if(synced.not) {
			TempoClock.default = TempoClock(~cps ? 1.0).permanent_(true);
			Server.default.latency = ~latency;
			"synced tempo clock at tempo: %. Server latency: %".format(~cps, ~latency).postln;
			synced = true
		};
		0.0 // return something so we don't get a warning:
		// no synth or sample named 'sync' could be found.
	}
});
)


// try it out:

(
SynthDef(\sinegrain, { | out=0, freq=440, sustain=0.05 |
	var env = EnvGen.ar(Env.perc(0.001, sustain, 0.2), doneAction:2);
	Out.ar(out, SinOsc.ar(freq, 0.5pi, env))
}
).add;

Pdef(\x,
	Pbind(
		\instrument, \sinegrain,
		\dur, 0.5,
		\note, Pshuf([0, 1, 2], inf) + Pshuf([[0, 5, 7], [0, 3, 11], 0, 0, 0], inf)
	)
).play
)
