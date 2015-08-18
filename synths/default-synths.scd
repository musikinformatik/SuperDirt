/*

Add your own instruments here.
They can be used in Tidal just as samples (ignoring the sample number, so instead of "bd:2" write "inr")

If your SuperDirt instance is assigned to the variable ~dirt, you can livecode these synths.
*/

(

// modulated band limited impulse
SynthDef(\imp, { |speed = 1, start=0, end=1, pan, accelerate, amp = 0.1, offset|
	var env, sound, dur, rate, phase;
	dur = (end - start) / speed;
	env = EnvGen.ar(Env.linen(0, 0.2, 0.8, amp, -4), timeScale:dur, doneAction:2);
	phase = Line.ar(start, end, dur);
	rate = (start + 1) * (speed + Sweep.kr(1, accelerate));
	sound = Blip.ar(rate.linexp(0, 1, 15 * [1, 2, 5], 200), 200 * phase).sum;
	env = env * ~dirt.gateCutGroup; // this synth can be freed by cutgroup mechanism
	~dirt.panOut(sound, pan, env)
}).add;

// live audio input
SynthDef(\in, { |speed = 1, start=0, end=1, pan, accelerate, amp = 0.1, offset|
	var env, sound, dur, rate, phase;
	dur = (end - start) / speed;
	env = EnvGen.ar(Env.linen(0, 0.2, 0.8, amp, -4), timeScale:dur, doneAction:2);
	phase = Line.ar(start, end, dur);
	rate = (start + 1) * (speed + Sweep.kr(1, accelerate));
	sound = SoundIn.ar([0, 1]); // stereo in
	env = env * ~dirt.gateCutGroup; // this synth can be freed by cutgroup mechanism
	~dirt.panOut(sound, pan, env)
}).add;

// pitch shifted live audio input
SynthDef(\inr, { |speed = 1, start=0, end=1, pan, accelerate, amp = 0.1, offset|
	var env, sound, dur, rate, phase;
	dur = (end - start) / speed;
	env = EnvGen.ar(Env.linen(0, 0.2, 0.8, amp, -4), timeScale:dur, doneAction:2);
	phase = Line.ar(start, end, dur);
	rate = (start + 1) * (speed + Sweep.kr(1, accelerate));
	sound = SoundIn.ar([0, 1]); // stereo in
	sound = PitchShift.ar(sound, 0.1, rate, 0.02, 0.01);
	env = env * ~dirt.gateCutGroup; // this synth can be freed by cutgroup mechanism
	~dirt.panOut(sound, pan, env)
}).add;
);

