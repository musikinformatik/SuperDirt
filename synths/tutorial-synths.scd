
// list of new SynthDefs, and in parentheses the special parameters they accept
// ("!" means it's not a standard Tidal param and needs to be defined)
// most of these SynthDefs use sustain to scale the overall envelope, and many use accelerate to provide a pitch glide
//
// tutorial1, tutorial2, tutorial3, tutorial4, tutorial5(f!),
// supermandolin(detune), supergong(voice,decay), superpiano(velocity,detune,muffle!,stereo!), superhex,
// superkick(pitch1,decay), superhat, supersnare(decay), superclap(delay,pitch1), super808(voice), supersiren

// a very basic starting point, just a 440Hz sine wave
(
SynthDef(\tutorial1, {|out|
	var sound = SinOsc.ar(440.0);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, 0.5));
}).add
);


// now let's add some better duration control, and support for pan
// Tidal's synth parameters magically show up as arguments to the SynthDef!
// so "sustain" can be used here and in Tidal to control the overall envelope
// overall gain is handled elsewhere by SuperDirt, so we don't need it in the envelope
(
SynthDef(\tutorial2, {|out, sustain=1, pan |
	var env = EnvGen.ar(Env.linen(0.01, 0.98, 0.01, 1,-3), timeScale:sustain, doneAction:2);
	var sound = SinOsc.ar(440.0);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add
);


// it's also nice to control the pitch
// the "n" parameter will be used as note number and converted to "freq" by SuperDirt
// also, "accelerate" will cause the pitch to drift
// in Tidal we'll need to say something like `sound "tutorial3:9"`(440 Hz, 9 is a5 in Tidal notation)
// to hear a reasonably high pitch
(
SynthDef(\tutorial3, {|out, sustain=1, pan, accelerate, freq |
	var env = EnvGen.ar(Env.linen(0.01, 0.98, 0.01, 1, -3), timeScale:sustain, doneAction:2);
	var sound = SinOsc.ar(freq * Line.kr(1,1+accelerate, sustain));
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add
);


// we can also make the envelope a more interesting percussive shape
(
SynthDef(\tutorial4, {|out, sustain=1, pan, accelerate, freq |
	var env = EnvGen.ar(Env.perc(0.001, 0.999, 1, -4), timeScale:sustain, doneAction:2);
	var sound = SinOsc.ar(freq * Line.kr(1,1+accelerate, sustain));
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add
);


// finally, as an example of how to add your own parameters, let's say we want precise control over frequency
// (there may be a built-in way to do this in the near future, for now treat this as an example of how to
// add your own parameter)
// we'll make a new "f" parameter instead of "n"
// to do this, we first need to this in Tidal: let f = pF "f"
// then "f" is usable as an argument to the synthdef, and in Tidal you can try
// d1 $ s "tutorial5/2" # f "[550,555]"
(
SynthDef(\tutorial5, {|out, sustain=1, pan, accelerate, f |
	var env = EnvGen.ar(Env.perc(0.001, 0.999, 1, -4), timeScale:sustain, doneAction:2);
	var sound = SinOsc.ar(f * Line.kr(1,1+accelerate, sustain));
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add
);
