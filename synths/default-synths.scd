/*

Add your own instruments here.
They can be used in Tidal just as samples (ignoring the sample number, so instead of "bd:2" write "inr")

// supported parameters are e.g.
// sustain, speed, endSpeed, start, end, pan, accelerate, offset, cps
// all instruments ought to use: out

If your SuperDirt instance is assigned to the variable ~dirt, you can livecode these synths.
*/

(

// modulated band limited impulse
SynthDef(\imp, { |out, sustain = 1, speed = 1, start=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, rate, phase;
	env = EnvGen.ar(Env.perc(0.001, sustain, amp * 0.1, -1), doneAction:2);
	phase = Line.ar(start, end, sustain);
	rate = (start + 1) * (speed + Sweep.kr(1, accelerate));
	sound = Blip.ar(rate.linexp(0, 1, 1, 220) * [1, 1.25, 1.51, 1.42], ExpRand(80, 118) * phase).sum;
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add;

// cursor modulated phase mod sines
SynthDef(\pmsin, { |out, sustain = 1,speed = 1, start=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, rate, phase, freq, modfreq;
	freq = MouseX.kr(30, 80).round.midicps;
	modfreq = MouseY.kr(1, 200, 1);
	amp = AmpCompA.kr(freq) * amp;
	env = EnvGen.ar(Env.perc(0.002, sustain, amp * 0.1, -1), doneAction:2);
	phase = Line.ar(start, end, sustain);
	rate = speed + Sweep.kr(1, accelerate);
	sound = SinOsc.ar(freq, SinOsc.ar(modfreq * (1..5), 0, 1 - phase * 10 * env / (1..5), 0.5pi)).sum;
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add;

// live audio input
SynthDef(\in, { |out, sustain = 1,speed = 1, start=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, rate, phase;
	phase = Line.ar(start, end, sustain);
	rate = (start + 1) * (speed + Sweep.kr(1, accelerate));
	sound = SoundIn.ar([0, 1]); // stereo in
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, amp)
	)
}).add;

// pitch shifted live audio input
SynthDef(\inr, { |out, sustain = 1,speed = 1, start=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, rate, phase;
	phase = Line.ar(start, end, sustain);
	rate = (start + 1) * (speed + Sweep.kr(1, accelerate));
	sound = SoundIn.ar([0, 1]); // stereo in
	sound = PitchShift.ar(sound, 0.1, rate, 0.02, 0.01);
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, amp)
	)
}).add;
);

