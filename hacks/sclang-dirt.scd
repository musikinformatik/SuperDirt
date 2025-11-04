
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
		\cut, Prand([1, 2, 3], inf),
		\n, Pwhite(0, 20, inf),
		\speed, Pbrown(1, 1.2, 0.01),
		\amp, Pwhite().linexp(0, 1, 0.001, 0.3),
		\clip, 2,
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
		\cutoff, [1345, 1000, 400] + Prand([0, 0, 0, 0, 0, 0, -100, 200, [-100, 210, 300] - 40], inf),
		\resonance, 0.7
	)

).quant_(1).play
)



// vowel tennis
(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\speed, 1,
		\sound, Pseq([\bd, \hh, \bd, \hh], inf),
		\vowel, Pn(Plazy {Pshuf([\a, \i, \o, \i, \u, [\i, \a], [\o, \u, \e]], rrand(3, 8)) }),
		\resonance, 0.7,
		\cut, 1,
		\shape, Pseq([0.5, 0.8, 0.3, 0.2, 0.2], inf),
		\dur, 0.25 * Pseq([1, 1/2, 1], inf)
	)
).play
)



// too many sounds
(
var howManyEffects = { rrand(1, 3) };
var howManySounds = 4;
var sounds = ~dirt.soundLibrary.bufferEvents.keys.asArray.scramble.keep(howManySounds);
var f = { |event|
	[
		{ ~vowel = "aeiou".choose.asSymbol },
		{ ~shape = rrand(0, 0.5) },
		{ ~hcutoff = exprand(200.0, 9000.0); ~hresonance = rrand(0.1, 0.7) },
		{ ~cutoff = exprand(200.0, 9000.0); ~resonance = rrand(0.1, 0.7) },
		{ ~bandf = exprand(200.0, 9000.0); ~bandq = rrand(0.5, 40) },
		{ ~crush = exprand(0.01, 0.5) },
		{ ~coarse = exprand(1, 8) },
		{ ~psrate = exprand(0.8, 10); ~psdisp = rrand(0, 2.0) },
		{ ~tremolorate = exprand(0.8, 8); ~tremolodepth = rrand(0.1, 2.0) },
		{ ~phasorrate = exprand(0.8, 2); ~phasordepth = rrand(0.1, 0.5) },
		{ ~delaytime = rrand(0.2, 1); ~delayfeedback = exprand(0.01, 0.2); ~delaySend = rrand(0.5, 1); ~delayAmp = rrand(0.1, 1) },
		{ ~room = 0; ~delayAmp = 0; ~leslie = 0 },
		{ ~size = rrand(0.2, 3); ~room = rrand(0.1, 1); ~dry = rrand(0.1, 1) },
		{ ~leslie = rrand(0.1, 1); ~lrate = exprand(0.8, 3); ~lsize = rrand(0.2, 1); },
	].scramble.keep(howManyEffects.value).do { |f| event.use(f) };
	event

};
var post = { |x|
	x.collect(_.round(0.01)).asPairs.clump(2).sort { |a, b| a.first < b.first }.do(_.postcs);
	"-------------------------".postln;
	x
};

Pdef(\x,
	Pbind(
		\type, \dirt,
		\s, Prand(sounds, inf),
		\n, Pwhite(0.0, 9, inf),
		\orbit, Prand([0, 1], inf),
		\cut, -1,
		\speed, Pwhite(0.7, 1.5),
		\dur, 0.125 * Pseq([1, 1/2, 1, 2, 2, 1/2], inf) * Pfunc { [1, 8].wchoose([0.9, 0.1]) },
	).collect(f).collect(post)
).play
)




