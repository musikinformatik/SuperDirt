/*

You can define arbitrary functions to be called from Tidal
The examples below assume you have stored dirt in a variable ~dirt, andyour first dirt bus in ~d1

NOTE: The interface for ~diversion (see bottom) may change!


*/

// d1 $ sound "tlalak bd*5 sn" |+| vowel "a e"



// adding function via addSynth
// the play function

~dirt.soundLibrary.addSynth(\test, (play: { "////////////// do whatever \\\\\\\\\\\\\\\\".postln }));

// test it either with tidal
// or from here:
SuperDirt.default = ~dirt;
(type:\dirt, dirt: ~dirt, s: \test).play;


// the playInside function


// example: start a synth explicitly


(
SynthDef(\plick, { |out, freq = 220, amp = 0.1, sustain = 1|
	var sig, env;
	env = EnvGen.ar(Env([0, amp, 0], [0.001, sustain]), doneAction:2);
	sig = SinOsc.ar(freq, LFNoise2.ar(XLine.kr(39, 300, sustain), Line.kr(15, 0, sustain)));
	Out.ar(out, sig * env);
}).add;


~dirt.soundLibrary.addSynth(\plack,
	(playInside: { |e|
		// make sure that you play it in the group and to the out
		(instrument: \plick, out: ~out, freq: ~freq, amp: ~amp, group: ~group).play
	})
)

)

// in tidal
d1 $ s "plack bd"
   # freq "<677 1000 200 7000>"
   # hcutoff "<3000 700 900>"
   # hresonance "0.05"


// example: trigger and route an Ndef from tidal

(
Ndef(\x, { Decay.kr(\trig.tr(0), 0.1) * PinkNoise.ar });

~dirt.soundLibrary.addSynth(\myNdef, (playInside: { |e|
		Ndef(\x).set(\trig, 1);
	// make sure that you play it in the group and to the out
		(instrument: \dirt_from, in: Ndef(\x).bus, out: ~out, amp: ~amp, group: ~group).play;
})
)
)

// in tidal
d1 $ s "myNdef bd"
   # hcutoff "<3000 700 900>"
   # hresonance "0.4"


SuperDirt.default = ~dirt;
(
Tdef(\x, {
	loop {
		(type:\dirt, s: \myNdef, hcutoff: rrand(300.0, 6000), hresonance: 0.8).play;
		0.2.wait
	}
}).play
)

// live code the Ndef
Ndef(\x, { Decay.kr(\trig.tr(0), 0.3) * PinkNoise.ar(1 ! 2) });
Ndef(\x, { Decay.kr(\trig.tr(0), 0.3) * Dust.ar(\trig.tr(0).lagud(0, 0.2) * 1000 ! 2) });









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




