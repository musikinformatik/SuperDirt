/*

Add your own instruments here.
They can be used in Tidal just as samples (ignoring the sample number, so instead of "bd:2" write "inr")

If your SuperDirt instance is assigned to the variable ~dirt, you can livecode these synths.
*/

(

// modulated band limited impulse
SynthDef(\imp, { |speed = 1, start=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, dur, rate, phase;
	dur = (end - start) / speed * 0.5;
	env = EnvGen.ar(Env.perc(0.002, dur, amp * 0.3, -1), timeScale:dur, doneAction:2);
	phase = Line.ar(start, end, dur);
	rate = (start + 1) * (speed + Sweep.kr(1, accelerate));
	sound = Blip.ar(rate.linexp(0, 1, 1, 220) * [1, 1.25, 1.51, 1.42], ExpRand(5, 118) * phase).sum;
	~dirt.panOut(sound, pan, env)
}).add;

// cursor modulated phase mod sines
SynthDef(\pmsin, { |speed = 1, start=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, dur, rate, phase, freq, modfreq;
	dur = (end - start) / speed * 0.5;
	freq = MouseX.kr(30, 80).round.midicps;
	modfreq = MouseY.kr(1, 200, 1);
	amp = AmpCompA.kr(freq) * amp;
	env = EnvGen.ar(Env.perc(0.002, dur, amp * 0.3, -1), timeScale:dur, doneAction:2);
	phase = Line.ar(start, end, dur);
	rate = speed + Sweep.kr(1, accelerate);
	sound = SinOsc.ar(freq, SinOsc.ar(modfreq * (1..5), 0, 1 - phase * 10 * env / (1..5), 0.5pi)).sum;
	~dirt.panOut(sound, pan, env)
}).add;

// live audio input
SynthDef(\in, { |speed = 1, start=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, dur, rate, phase;
	dur = (end - start) / speed;
	env = EnvGen.ar(Env.linen(0, 0.2, 0.8, amp, -4), timeScale:dur, doneAction:2);
	phase = Line.ar(start, end, dur);
	rate = (start + 1) * (speed + Sweep.kr(1, accelerate));
	sound = SoundIn.ar([0, 1]); // stereo in
	~dirt.panOut(sound, pan, env)
}).add;

// pitch shifted live audio input
SynthDef(\inr, { |speed = 1, start=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, dur, rate, phase;
	dur = (end - start) / speed;
	env = EnvGen.ar(Env.linen(0, 0.2, 0.8, amp, -4), timeScale:dur, doneAction:2);
	phase = Line.ar(start, end, dur);
	rate = (start + 1) * (speed + Sweep.kr(1, accelerate));
	sound = SoundIn.ar([0, 1]); // stereo in
	sound = PitchShift.ar(sound, 0.1, rate, 0.02, 0.01);
	~dirt.panOut(sound, pan, env)
}).add;
);

