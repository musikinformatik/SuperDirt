/*

Add your own instruments here.
They can be used in Tidal just as samples (ignoring the sample number, so instead of "bd:2" write "inr")

// supported parameters are e.g.
// sustain, speed, endSpeed, begin, end, pan, accelerate, offset, cps
// all instruments ought to use: out

If your SuperDirt instance is assigned to the variable ~dirt, you can livecode these synths.
*/

(

// modulated band limited impulse
SynthDef(\imp, { |out, sustain = 1, note = 0, speed = 1, begin=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, rate, phase;
	env = EnvGen.ar(Env.perc(0.01, 0.99, amp * 0.1, -1), timeScale:sustain, doneAction:2);
	phase = Line.kr(begin, end, sustain);
	rate = (begin + 1) * (speed + Sweep.kr(1, accelerate));
	sound = Blip.ar(rate.linexp(0, 1, 1, 220) * [1, 1.25, 1.51, 1.42] * note.midiratio, ExpRand(80, 118) * phase).sum;
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add;

// cursor modulated phase mod sines
SynthDef(\pmsin, { |out, sustain = 1, note = 0, speed = 1, begin=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, rate, phase, freq, modfreq;
	freq = (MouseX.kr(30, 80).round + note).midicps;
	modfreq = MouseY.kr(1, 200, 1);
	amp = AmpCompA.kr(freq) * amp;
	env = EnvGen.ar(Env.perc(0.002, sustain, amp * 0.1, -1), doneAction:2);
	phase = Line.ar(begin, end, sustain);
	rate = speed + Sweep.kr(1, accelerate);
	sound = SinOsc.ar(freq, SinOsc.ar(modfreq * (1..5), 0, 1 - phase * 10 * env / (1..5), 0.5pi)).sum;
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add;

// live audio input
SynthDef(\in, { |out, sustain = 1, speed = 1, begin=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, rate, phase;
	phase = Line.ar(begin, end, sustain);
	rate = (begin + 1) * (speed + Sweep.kr(1, accelerate));
	sound = SoundIn.ar([0, 1]); // stereo in
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, amp)
	)
}).add;

// pitch shifted live audio input
SynthDef(\inr, { |out, sustain = 1, note = 0, speed = 1, begin=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, rate, phase;
	phase = Line.ar(begin, end, sustain);
	rate = (begin + 1) * (speed + Sweep.kr(1, accelerate)) * note.midiratio;
	sound = SoundIn.ar([0, 1]); // stereo in
	sound = PitchShift.ar(sound, 0.1, rate, 0.02, 0.01);
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, amp)
	)
}).add;
);

// gabor grain
(
SynthDef(\gabor, { |out, sustain = 0.03, note = 0, amp = 1, pan = 0, width = 0.3|
	var env, sound, freq;
	freq = (note + 60).midicps;
	sound = SinOsc.ar(freq, 0.5pi);
	env = LFGauss.ar(sustain, width, loop: 0);
	OffsetOut.ar(out,
		DirtPan.ar(env * sound, ~dirt.numChannels, pan, amp)
	)
}).add;
);

(
var numChannels = ~dirt.numChannels;

// list of new SynthDefs, and in parentheses the special parameters they accept
// ("!" means it's not a standard Tidal param and needs to be defined)
// most SynthDefs use speed to scale the overall envelope, and many use accelerate to provide a pitch glide
//
// tutorial1, tutorial2, tutorial3, tutorial4, tutorial5(f!),
// supermandolin(detune), supergong(voice,decay), superpiano(velocity,detune,muffle!,stereo!), superhex,
// superkick(pitch1,decay), superhat, supersnare(decay), superclap(delay,pitch1), super808(voice), supersiren

// a very basic starting point, just a 440Hz sine wave
SynthDef(\tutorial1, {|out|
	var sound = SinOsc.ar(440.0);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, 0.5));
}).add;

// now let's add some better duration control, and support for pan
// Tidal's synth parameters magically show up as arguments to the SynthDef!
// overall gain is handled elsewhere by SuperDirt, so we don't need it in the envelope
SynthDef(\tutorial2, {|out, begin=0, end=1, pan, speed=1 |
	var dur = (end-begin)/speed;
	var env = EnvGen.ar(Env.linen(0.01, dur, 0.01, 1,-3), timeScale:dur, doneAction:2);
	var sound = SinOsc.ar(440.0);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add;

// it's also nice to control the pitch
// using midicps means the "n" parameter will be used as MIDI note number
// also, "accelerate" will cause the pitch to drift
// in Tidal we'll need to say something like `sound "tutorial3:69"` to hear a reasonably high pitch
SynthDef(\tutorial3, {|out, begin=0, end=1, pan, speed=1, accelerate, n |
	var dur = (end-begin)/speed;
	var env = EnvGen.ar(Env.linen(0.01, dur, 0.01, 1, -3), timeScale:dur, doneAction:2);
	var sound = SinOsc.ar(n.midicps * Line.kr(1,1+accelerate));
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add;

// we can also make the envelope a more interesting percussive shape
// note how speed affects the envelope
SynthDef(\tutorial4, {|out, begin=0, end=1, pan, speed=1, accelerate, n |
	var dur = (end-begin)/speed;
	var env = EnvGen.ar(Env.perc(0.001/speed, 1/speed, 1, -4), timeScale:dur, doneAction:2);
	var sound = SinOsc.ar(n.midicps * Line.kr(1,1+accelerate));
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add;

// finally, as an example of how to add your own parameters, let's say we want precise control over frequency
// we'll make a new "f" parameter instead of "n"
// to do this, we first need to this in Tidal: let (f, f_p) = pF "f" (Just 440)
// then "f" is usable as an argument to the synthdef, and in Tidal you can try
// d1 $ s "tutorial5/2" # f "[550,555]" # speed "1"
SynthDef(\tutorial5, {|out, begin=0, end=1, pan, speed=1, accelerate, f |
	var dur = (end-begin)/speed;
	var env = EnvGen.ar(Env.perc(0.001/speed, 1/speed, 1, -4), timeScale:dur, doneAction:2);
	var sound = SinOsc.ar(f * Line.kr(1,1+accelerate));
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add;

// physical modeling of a vibrating string, using a delay line (CombL) excited by an intial pulse (Impulse)
// To make it a bit richer, I've combined two slightly detuned delay lines
// "accelerate" is used for a pitch glide, and "speed" changes the envelope timescale
SynthDef(\supermandolin, {|out, speed=1, begin=0, end=1, pan, accelerate, n, detune=0.2 |
	var dur = (end-begin)/speed;
	var env = EnvGen.ar(Env.linen(0.002, dur, 0.002, 1,-3), timeScale:dur, doneAction:2);
	var sound = Decay.ar(Impulse.ar(0,0,0.1), 0.1*n/69) * WhiteNoise.ar;
	var pitch = n.midicps * Line.kr(1, 1+accelerate);
	sound = CombL.ar(sound, 0.05, pitch.reciprocal*(1-(detune/100)), dur)
	          + CombL.ar(sound, 0.05, pitch.reciprocal*(1+(detune/100)), dur);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add;

// an example of additive synthesis, building up a gong-like noise from a sum of sine-wave harmonics
// notice how the envelope timescale and amplitude can be scaled as a function of the harmonic frequency
// "voice" provides something like a tone knob, and "decay" adjusts how the harmonics decay
// as in the other SynthDefs, "speed" affects the overall envelope timescale and "accelerate" for pitch glide
// for a demo, try this in Tidal
// d1 $ n (slow 2 $ fmap ((+50) . (*7)) $ run 8) # s "supergong" # decay "[1 0.2]/4" # voice "[0.5 0]/8"
SynthDef(\supergong,{|out, speed=1, begin=0, end=1, pan, accelerate, n, voice=0, decay=1 |
	var dur = (end-begin)/speed;
	var basefreq = n.midicps;
	// lowest modes for clamped circular plate
	var freqlist =[1.000,  2.081,  3.414,  3.893,  4.995,  5.954,  6.819,  8.280,  8.722,  8.882, 10.868, 11.180, 11.754,
		13.710, 13.715, 15.057, 15.484, 16.469, 16.817, 18.628]**1.0;
	var tscale = 100.0 / basefreq / (freqlist**(2-clip(decay,0,2)));
	var ascale =freqlist**clip(voice,0,4);
	var sound = Mix.arFill(15, {arg i; EnvGen.ar(Env.perc(0.01*tscale[i], 0.5*tscale[i], 0.2*ascale[i] ), timeScale:dur*5)
		* SinOsc.ar(basefreq * freqlist[i] * Line.kr(1, 1+accelerate))});
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan))
}).add;

// hooking into a nice synth piano already in supercollider
// uses the "velocity" parameter to affect how hard the keys are pressed
// "speed" controls envelope and decay time
SynthDef(\superpiano,{|out, speed=1, begin=0, end=1, pan, velocity=1, detune=0.1, muffle=1, stereo=0.2, n |
	var dur = (end-begin)/speed;
	var env = EnvGen.ar(Env.linen(0.002, dur, 0.002, 1,-3), timeScale:dur, doneAction:2);
	// the +0.01 to freq is because of edge case rounding internal to the MdaPiano synth
	var sound = MdaPiano.ar(n.midicps+0.01, vel:velocity*100, hard:0.8*velocity, decay:0.4*dur,
		tune:0.5, random:0.05, stretch:detune, muffle:0.8*muffle, stereo:stereo);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add;

// waveguide mesh, hexagonal drum-like membrane
SynthDef(\superhex,{|out, speed=1, begin=0, end=1, pan, n, accelerate |
	var dur = (end-begin)/speed;
	var env = EnvGen.ar(Env.linen(0.02, dur, 0.02, 1,-3), timeScale:dur*speed, doneAction:2);
	var tension = 0.05*n.midicps/400 * Line.kr(1,accelerate+1);
	var loss = 1.0 - (0.01 * speed / n.midicps);
	var sound = MembraneHexagon.ar(Decay.ar(Impulse.ar(0,0,1), 0.01), tension, loss);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add;

// Kick Drum using Rumble-San's implementation as a starting point
// http://blog.rumblesan.com/post/53271713518/drum-sounds-in-supercollider-part-1
// "n" controls the kick frequency
// "speed" affects overall envelope timescale, "accelerate" sweeps the click filter freq,
// "pitch1" affects the click frequency, and "decay" changes the click duration relative to the overall timescale
SynthDef(\superkick, {|out, speed=1, begin=0, end=1, pan, accelerate, n, pitch1=1, decay=1 |
	var env, sound, dur, clickdur;
	dur = 1.0 * (end - begin)/speed;
	env = EnvGen.ar(Env.linen(0.01, 0, 0.5, 1, -3), timeScale:dur, doneAction:2);
	sound = SinOsc.ar((n+34.5).midicps);
	clickdur = 0.02*dur*decay;
	sound = sound + (LPF.ar(WhiteNoise.ar(1), 1500*pitch1*Line.kr(1,1+accelerate,clickdur) ) * Line.ar(1, 0, clickdur));
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add;

// A vaguely 808-ish kick drum
// "n" controls the chirp frequency, "speed" the filter sweep speed, and "voice" the sinewave feedback
SynthDef(\super808, {|out, speed=1, begin=0, end=1, pan, voice=0, n |
	var env, sound, dur, freq;
	dur = 1.0 * (end - begin)/speed;
	n = ((n>0)*n) + ((n<1)*3);
	freq = (n*10).midicps;
	env = EnvGen.ar(Env.linen(0.01, 0, 1, 1, -3), timeScale:dur, doneAction:2);
	sound = LPF.ar(SinOscFB.ar(XLine.ar(100*freq, freq, 0.025/speed), voice), 9000);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add;

// Hi-hat using Rumble-San's implementation as a starting point
// http://blog.rumblesan.com/post/53271713518/drum-sounds-in-supercollider-part-1
// using "n" in a weird way to provide some variation on the frequency
// "speed" affects the overall envelope rate, "accelerate" sweeps the filter
SynthDef(\superhat, {|out, speed=1, begin=0, end=1, pan, accelerate, n |
	var env, sound, dur, accel, freq;
	dur = 1.0 * (end - begin)/speed;
	env = EnvGen.ar(Env.linen(0.01, 0, 0.3, 1, -3), timeScale:dur, doneAction:2);
	accel = Line.kr(1, 1+accelerate, 0.2*dur);
	freq = 2000*accel*(n/5 + 1).wrap(0.5,2);
	sound = HPF.ar(LPF.ar(WhiteNoise.ar(1), 3*freq), freq);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add;

// Snare drum using Rumble-San's implementation as a starting point
// http://blog.rumblesan.com/post/53271713909/drum-sounds-in-supercollider-part-2
// again using "n" for some variation on frequency, "decay" for scaling noise duration relative to tonal part
// "speed" for overall timescale, "accelerate" for tonal glide
SynthDef(\supersnare, {|out, speed=1, begin=0, end=1, pan, accelerate, n, decay=1 |
	var env, sound, dur, accel;
	dur = 1.0 * (end - begin)/speed;
	env = EnvGen.ar(Env.linen(0.01, 0, 0.6, 1, -3), timeScale:dur, doneAction:2);
	accel = Line.kr(1, 1+accelerate, 0.2);
	sound = LPF.ar(Pulse.ar(100*accel*(n/5+1).wrap(0.5,2)), Line.ar(1030, 30, 0.2*dur));
	sound = sound + (BPF.ar(HPF.ar(WhiteNoise.ar(1), 500), 1500) * Line.ar(1, 0, 0.2*decay));
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add;

// Hand clap using Rumble-San's implementation as a starting point
// http://blog.rumblesan.com/post/53271713909/drum-sounds-in-supercollider-part-2
// "delay" controls the echo delay, "speed" will affect the decay time, "n" changes how spread is calculated
// "pitch1" will scale the bandpass frequency
SynthDef(\superclap, {|out, speed=1, begin=0, end=1, pan, n, delay=1, pitch1=1 |
	var env, sound, dur;
	var spr = 0.005 * delay;
	dur = 1.0 * (end - begin)/speed;
	env = EnvGen.ar(Env.linen(0.01, 0, 0.6, 1, -3), timeScale:dur, doneAction:2);
	sound = BPF.ar(LPF.ar(WhiteNoise.ar(1), 7500*pitch1), 1500*pitch1);
	sound = Mix.arFill(4, {arg i; sound * 0.5 * EnvGen.ar(Env.new([0,0,1,0],[spr*(i**(n.clip(0,5)+1)),0,0.04/speed]))});
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add;

// a controllable synth siren, defaults to 1 second, draw it out with "speed"
SynthDef(\supersiren, {|out, speed=1, begin=0, end=1, pan, n |
	var env, sound, dur, freq;
	dur = (end-begin)/speed;
	freq = n.midicps;
	env = EnvGen.ar(Env.linen(0.05, 0.9, 0.05, 1, -2), timeScale:dur, doneAction:2);
	sound = VarSaw.ar(freq * (1.0 + EnvGen.kr(Env.linen(0.25,0.5,0.25,3,0), timeScale:dur, doneAction:2)), 0, Line.kr(0.05,1,dur));
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add;

)