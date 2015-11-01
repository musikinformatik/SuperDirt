/*

You can define arbitrary functions to be called from Tidal
This assumes you have stored dirt in a variable ~dirt, andyour first dirt bus in ~d1

NOTE: The interface for this may change!

*/

// d1 $ sound "tlalak bd*5 sn" |+| vowel "a e"

(
var diversions = ();  // make a dictionary of functions
~diversions = diversions; // make it available out of scope
~diversions[\tlalak] = {
	"hello tlalak".postln;
};
// use the "diversion" key as a hook for playing the synth
~d1.defaultParentEvent[\diversion] = { diversions[~sound].value };
)

// execute arbitrary sc code
// you can livecode this
(
~diversions[\tlalak]  = {
	Pfindur(~sustain,
		Pbind(
			\dur, 0.04,
			\note, Pbrown(-15, 15 ! 5, 0.3, inf) + 16,
			\out, ~out, \pan, ~pan, \amp, ~amp * 0.1
		)
	).play
};
)


// take it out again.
~diversions[\tlalak]  = nil;


/*

forward midi
(untested!)

*/

MIDIClient.init;

(
var midiOut = MIDIOut(0);
var chan = 16;

~diversions[\midi]  = {
	var note = ~speed.ratiomidi + 60;
	var vel = ~amp * 128;
	midiOut.noteOn(chan, note, vel)
	SystemClock.sched(~sustain, {
		midiOut.noteOff(chan, note, vel);
	}
};
)

