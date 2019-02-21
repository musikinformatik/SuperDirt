/*

You can define arbitrary functions to be called from Tidal
This assumes you have stored dirt in a variable ~dirt, andyour first dirt bus in ~d1

NOTE: The interface for this may change!


*/

// d1 $ sound "tlalak bd*5 sn" |+| vowel "a e"


// Note that you may want to first try
// to simply use the addSynth(name, event) schema:

~dirt.soundLibrary.addSynth(\test, (play: { "////////////// do whatever \\\\\\\\\\\\\\\\".postln }));

// test it either with tidal
// or from here:
(type:\dirt, dirt: ~dirt, s: \test).play;


/*

But you can also divert more fundamentally.

*/


// simple example.
// execute arbitrary code
~dirt.orbits[0].defaultParentEvent[\diversion] = { "\n*** now just this happens. *** \n".postln; };

// test it either with tidal
// or from here:
(type:\dirt, dirt: ~dirt).play;

// you can pull out parameters:
~dirt.orbits[0].defaultParentEvent[\diversion] = { "\n***".postln; ~s.postln };

(type:\dirt, s:\cp, dirt: ~dirt).play;


// but it is not very useful like this
// you may prefer to divert only for specific sound values (values of # sound)

(
var diversions = ();  // make a dictionary of functions
~diversions = diversions; // make it available out of scope
// use the "diversion" key as a hook for playing the synth
// return nil (unless you want the default action to also happen)
~d1.defaultParentEvent[\diversion] = { diversions[~s].value };
)

// now you can populate the dictionary with specific diversions.
// say you want to divert the sound tlalak:

(
~diversions[\tlalak] = {
	"hello tlalak".postln;
};
~diversions[\patatl] = {
	"hello potato 0oOoOOoOoO0".postln;
}
);

(type:\dirt, s:\tlalak, dirt: ~dirt).play;
(type:\dirt, s:\patatl, dirt: ~dirt).play;

// execute arbitrary sc code
// you can livecode this
(
~diversions[\tlalak]  = {
	Pfindur(~sustain ? 1,
		Pbind(
			\dur, 0.04,
			\note, Pbrown(-15, 15 ! 5, 0.3, inf) + 16,
			\out, ~out, \pan, ~pan, \amp, ~amp * 0.1
		)
	).play
};
)


(type:\dirt, s:\tlalak, dirt: ~dirt, out: 0, sustain: 2).play;



// take them out again.
~diversions[\tlalak]  = nil;
~diversions[\patatl]  = nil;




