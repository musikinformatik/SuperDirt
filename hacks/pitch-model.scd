/*

adding new pitch models to a dirt orbit

*/



// to test it you could use this synth, and run in tidal

(
SynthDef(\testnote, { |out, sustain = 0.2, freq = 0, amp = 1, pan = 0, width = 0.3|
	var env, sound;
	sound = SinOsc.ar(freq, 0.5pi);
	env = EnvGen.ar(Env.perc(Rand(0.01, 0.02), sustain * Rand(1, 1.5)));
	OffsetOut.ar(out,
		DirtPan.ar(env * sound, ~dirt.numChannels, pan, amp)
	)
}).add;
);


d1 $ slow 2 $ sound "testnote*16" # n (run 16)


// the default function is kept here
// it takes ~n as one of its variables
~dirt.orbits[0].defaultParentEvent[\freq].cs


// we modify it step by step

// post what we have

~dirt.orbits[0].set(\freq, #{ ~n.postln.midicps.postln });

// play half note higher

~dirt.orbits[0].set(\freq, #{ (~n + 1).midicps });

// detune by a random frequency between -10 and 10 Hz

~dirt.orbits[0].set(\freq, #{ ~n.midicps + 10.0.rand2 });


// use an extended ocatve and an 11 TET scale

// note: for now, you should hen use values in the note range, not midinotes.

~dirt.orbits[0].set(\freq, #{ 440 * (2.1 ** (~n / 11)) });

// interpret ~n as an overtone

~dirt.orbits[0].set(\freq, #{ 220 * (~n + 1) });


// use the supercollider event pitch model, as explained in Event.help (last diagram on the page)
// we interpret ~n as scale degree
// defining other parameters in tidal you can send them from there on a note by note basis.

(
~dirt.orbits[0].set(\freq, #{
	var degree = ~n;
	Event.default.use {
		~degree = degree;
		~freq.value
	}
}
)
);

// modal transposition
(
~dirt.orbits[0].set(\freq, #{
	var degree = ~n;
	Event.default.use {
		~degree = degree;
		~mtranspose = 2;
		~freq.value
	}
}
)
);



// you can set parameters like scale, steps per octave etc.
(
~dirt.orbits[0].set(\freq, #{
	var degree = ~n;
	Event.default.use {
		~degree = degree;
		~scale = [0, 4, 5, 7, 8];
		~stepsPerOctave = 10;
		~freq.value
	}
}
)
);


// back to default.
~dirt.orbits[0].set(\freq, #{ ~n.midicps });




