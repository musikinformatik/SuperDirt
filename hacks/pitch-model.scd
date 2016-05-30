/*

adding new pitch models to a dirt orbit

*/




// the default function is kept here
// it takes ~n as one of its variables
~dirt.orbits[0].defaultParentEvent[\freq].cs


// we modify it step by step

// post what we have

~dirt.orbits[0].set(\freq, #{ (~n.postln + 60).midicps.postln });

// play half note higher

~dirt.orbits[0].set(\freq, #{ (~n + 61).midicps });

// detune by a random frequency between -10 and 10 Hz

~dirt.orbits[0].set(\freq, #{ (~n + 60).midicps + 10.0.rand2 });


// use an extended ocatve and an 11 TET scale

~dirt.orbits[0].set(\freq, #{ 440 * (2.1 ** (~n / 11)) });

// interpret ~n as an overtone

~dirt.orbits[0].set(\freq, #{ 220 * (~n + 1) });


// use the supercollider event pitch model, as explained in Event.help (last diagram on the page)
// we interpret ~n as scale degree
// defining other parameters in tidal you can send them from there on a note by note basis.

(
~dirt.orbits[0].set(\freq,
	#{
		var degree = ~n;
		Event.default.use {
			~degree = degree;
			~freq.value
		}
	}
);


// you can set parameters like scale, steps per octave etc.
(
~dirt.orbits[0].set(\freq,
	#{
		var degree = ~n;
		Event.default.use {
			~degree = degree;
			~scale = [0, 4, 5, 7, 8];
			~stepsPerOctave = 10;
			~freq.value
		}
	}
);


// or modal transposition
(
~dirt.orbits[0].set(\freq,
	#{
		var degree = ~n;
		Event.default.use {
			~degree = degree;
			~mtranspose = 2;
			~freq.value
		}
	}
);







