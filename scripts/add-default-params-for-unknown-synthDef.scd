
// like this, you can add default parameters that are used when a SynthDef isn't known to sclang.

(
~dirt.soundLibrary.defaultEvent = (
	msgFunc: { |out, freq=440, amp=0.1, pan=0, sustain=1|
		[
			\out, out,
			\freq, freq,
			\amp, amp,
			\pan, pan,
			\sustain, sustain
		].asControlInput
	}
)
);




// this synthdef is just a test
// the message "send" simulates an externally loaded synthdef.
(
SynthDef(\ghk, { |freq, out, sustain|
	Out.ar(out, SinOsc.ar(freq) * XLine.kr(1, 0.01, sustain, doneAction:2))
}).send;
)
