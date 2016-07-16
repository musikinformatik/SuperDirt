


(
SynthDef(\gendy, { |out, sustain = 1, freq = 440, pan, fratio = 0|
	var env, sound, gfreq1, gfreq2;
	gfreq1 = freq * (2 ** fratio.neg);
	gfreq2 = freq * (2 ** fratio);
	env = EnvGen.ar(Env.sine(sustain), doneAction:2);
	sound = Gendy1.ar(1, 1, 1, 1, gfreq1, gfreq2);
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add
);

// play it in tidal:
// d1 $ s "gendy" # legato "1.2"


~dirt.set(\fratio, Ndef(\ctrl1));


Ndef(\ctrl1, 0);
Ndef(\ctrl1, 0.1);



Ndef(\ctrl1, { MouseX.kr(0, 2) });

// you can use a MIDI controller or any external device to set Ndef(\ctrl1)

