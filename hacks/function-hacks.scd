/*

You can define arbitrary functions to be called from Tidal
This assumes you have stored dirt in a variable ~dirt, andyour first dirt bus in ~d1

NOTE: The interface for this may change!

*/

// d1 $ sound "tlalak bd*5 sn" |+| vowel "a e"

(
~event = ~d1.defaultParentEvent;
~event[\dict] = ();  // make a dictionary of functions
~event[\dict][\tlalak] = {
	"hello tlalak".postln;
};
// use the "diversion" key as a hook for playing the synth
~event[\diversion] = {
	~dict[~sound].value(~d1)
};)
)

// execute arbitrary sc code. The dirtbus is the argument
(
~event[\dict][\tlalak]  = {
	Pfindur(~sustain, Pbind(\dur, 0.04, \note, Pbrown(-15, 15 ! 5, 0.3, inf), \out, ~out, \pan, ~pan)).play
};
)



/*

forward midi
(untested!)

*/

MIDIClient.init;

(
var midiOut = MIDIOut(0);
var chan = 16;

~event[\dict][\midi]  = {
	var note = ~speed.ratiomidi + 60;
	var vel = ~amp * 128;
	midiOut.noteOn(chan, note, vel)
	SystemClock.sched(~sustain, {
		midiOut.noteOff(chan, note, vel);
	}
};
)

