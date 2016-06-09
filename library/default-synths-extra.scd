


// physical modeling of a vibrating string, using a delay line (CombL) excited by an intial pulse (Impulse)
// To make it a bit richer, I've combined two slightly detuned delay lines
// "accelerate" is used for a pitch glide, and "sustain" changes the envelope timescale
(
	SynthDef(\supermandolin, {|out, sustain=1, pan, accelerate, freq, detune=0.2 |
		var env = EnvGen.ar(Env.linen(0.002, 0.996, 0.002, 1,-3), timeScale:sustain, doneAction:2);
		var sound = Decay.ar(Impulse.ar(0,0,0.1), 0.1*(freq.cpsmidi)/69) * WhiteNoise.ar;
		var pitch = freq * Line.kr(1, 1+accelerate, sustain);
		sound = CombL.ar(sound, 0.05, pitch.reciprocal*(1-(detune/100)), sustain)
		+ CombL.ar(sound, 0.05, pitch.reciprocal*(1+(detune/100)), sustain);
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// an example of additive synthesis, building up a gong-like noise from a sum of sine-wave harmonics
// notice how the envelope timescale and amplitude can be scaled as a function of the harmonic frequency
// "voice" provides something like a tone knob, and "decay" adjusts how the harmonics decay
// as in the other SynthDefs, "sustain" affects the overall envelope timescale and "accelerate" for pitch glide
// for a demo, try this in Tidal
// d1 $ n (slow 2 $ fmap (*7) $ run 8) # s "supergong" # decay "[1 0.2]/4" # voice "[0.5 0]/8"
(
	SynthDef(\supergong,{|out, sustain=1, pan, accelerate, freq, voice=0, decay=1 |
		// lowest modes for clamped circular plate
		var freqlist =[1.000,  2.081,  3.414,  3.893,  4.995,  5.954,  6.819,  8.280,  8.722,  8.882, 10.868, 11.180, 11.754,
			13.710, 13.715, 15.057, 15.484, 16.469, 16.817, 18.628]**1.0;
		var tscale = 100.0 / freq / (freqlist**(2-clip(decay,0,2)));
		var ascale =freqlist**clip(voice,0,4);
		var sound = Mix.arFill(15, {arg i; EnvGen.ar(Env.perc(0.01*tscale[i], 0.5*tscale[i], 0.2*ascale[i] ), timeScale:sustain*5)
			* SinOsc.ar(freq * freqlist[i] * Line.kr(1, 1+accelerate, sustain))});
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan))
	}).add
);


// hooking into a nice synth piano already in supercollider
// uses the "velocity" parameter to affect how hard the keys are pressed
// "sustain" controls envelope and decay time
(
	SynthDef(\superpiano,{|out, sustain=1, pan, velocity=1, detune=0.1, muffle=1, stereo=0.2, freq=440 |
		var env = EnvGen.ar(Env.linen(0.002, 0.996, 0.002, 1,-3), timeScale:sustain, doneAction:2);
		// the +0.01 to freq is because of edge case rounding internal to the MdaPiano synth
		var sound = MdaPiano.ar(freq+0.01, vel:velocity*100, hard:0.8*velocity, decay:0.1*sustain,
			tune:0.5, random:0.05, stretch:detune, muffle:0.8*muffle, stereo:stereo);
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);

// waveguide mesh, hexagonal drum-like membrane
(
	SynthDef(\superhex,{|out, speed=1, sustain=1, pan, freq, accelerate |
		var env = EnvGen.ar(Env.linen(0.02, 0.96, 0.02, 1,-3), timeScale:sustain, doneAction:2);
		var tension = 0.05*freq/400 * Line.kr(1,accelerate+1, sustain);
		var loss = 1.0 - (0.01 * speed / freq);
		var sound = MembraneHexagon.ar(Decay.ar(Impulse.ar(0,0,1), 0.01), tension, loss);
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// Kick Drum using Rumble-San's implementation as a starting point
// http://blog.rumblesan.com/post/53271713518/drum-sounds-in-supercollider-part-1
// "n" controls the kick frequency in a nonstandard way
// "sustain" affects overall envelope timescale, "accelerate" sweeps the click filter freq,
// "pitch1" affects the click frequency, and "decay" changes the click duration relative to the overall timescale
(
	SynthDef(\superkick, {|out, sustain=1, pan, accelerate, n, pitch1=1, decay=1 |
		var env, sound, dur, clickdur;
		env = EnvGen.ar(Env.linen(0.01, 0, 0.5, 1, -3), timeScale:sustain, doneAction:2);
		sound = SinOsc.ar((n - 25.5).midicps);
		clickdur = 0.02*sustain*decay;
		sound = sound + (LPF.ar(WhiteNoise.ar(1), 1500*pitch1*Line.kr(1,1+accelerate,clickdur) ) * Line.ar(1, 0, clickdur));
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// A vaguely 808-ish kick drum
// "n" controls the chirp frequency, "sustain" the overall timescale, "speed" the filter sweep speed,
// and "voice" the sinewave feedback
(
	SynthDef(\super808, {|out, speed=1, sustain=1, pan, voice=0, n |
		var env, sound, freq;
		n = ((n>0)*n) + ((n<1)*3);
		freq = (n*10).midicps;
		env = EnvGen.ar(Env.linen(0.01, 0, 1, 1, -3), timeScale:sustain, doneAction:2);
		sound = LPF.ar(SinOscFB.ar(XLine.ar(freq.expexp(10, 2000, 1000, 8000), freq, 0.025/speed), voice), 9000);
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// Hi-hat using Rumble-San's implementation as a starting point
// http://blog.rumblesan.com/post/53271713518/drum-sounds-in-supercollider-part-1
// using "n" in a weird way to provide some variation on the frequency
// "sustain" affects the overall envelope rate, "accelerate" sweeps the filter
(
	SynthDef(\superhat, {|out, sustain=1, pan, accelerate, n |
		var env, sound, accel, freq;
		env = EnvGen.ar(Env.linen(0.01, 0, 0.3, 1, -3), timeScale:sustain, doneAction:2);
		accel = Line.kr(1, 1+accelerate, 0.2*sustain);
		freq = 2000*accel*(n/5 + 1).wrap(0.5,2);
		sound = HPF.ar(LPF.ar(WhiteNoise.ar(1), 3*freq), freq);
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// Snare drum using Rumble-San's implementation as a starting point
// http://blog.rumblesan.com/post/53271713909/drum-sounds-in-supercollider-part-2
// again using "n" for some variation on frequency, "decay" for scaling noise duration relative to tonal part
// "sustain" for overall timescale, "accelerate" for tonal glide
(
	SynthDef(\supersnare, {|out, sustain=1, pan, accelerate, n, decay=1 |
		var env, sound, accel;
		env = EnvGen.ar(Env.linen(0.01, 0, 0.6, 1, -3), timeScale:sustain, doneAction:2);
		accel = Line.kr(1, 1+accelerate, 0.2);
		sound = LPF.ar(Pulse.ar(100*accel*(n/5+1).wrap(0.5,2)), Line.ar(1030, 30, 0.2*sustain));
		sound = sound + (BPF.ar(HPF.ar(WhiteNoise.ar(1), 500), 1500) * Line.ar(1, 0, 0.2*decay));
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// Hand clap using Rumble-San's implementation as a starting point
// http://blog.rumblesan.com/post/53271713909/drum-sounds-in-supercollider-part-2
// "delay" controls the echo delay, "speed" will affect the decay time, "n" changes how spread is calculated
// "pitch1" will scale the bandpass frequency, and "sustain" the overall timescale
(
	SynthDef(\superclap, {|out, speed=1, sustain=1, pan, n, delay=1, pitch1=1 |
		var env, sound;
		var spr = 0.005 * delay;
		env = EnvGen.ar(Env.linen(0.01, 0, 0.6, 1, -3), timeScale:sustain, doneAction:2);
		sound = BPF.ar(LPF.ar(WhiteNoise.ar(1), 7500*pitch1), 1500*pitch1);
		sound = Mix.arFill(4, {arg i; sound * 0.5 * EnvGen.ar(Env.new([0,0,1,0],[spr*(i**(n.clip(0,5)+1)),0,0.04/speed]))});
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// a controllable synth siren, defaults to 1 second, draw it out with "sustain"
(
	SynthDef(\supersiren, {|out, sustain=1, pan, freq |
		var env, sound;
		env = EnvGen.ar(Env.linen(0.05, 0.9, 0.05, 1, -2), timeScale:sustain, doneAction:2);
		sound = VarSaw.ar(freq * (1.0 + EnvGen.kr(Env.linen(0.25,0.5,0.25,3,0), timeScale:sustain, doneAction:2)),
			0, width:Line.kr(0.05,1,sustain));
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// The next four synths respond to the following parameters in addition to gain, pan, n, and all the "effect" parameters
// (including attack, hold, and release).  Default values in parentheses.
//
// sustain - scales overall duration
// decay(0) - amount of decay after initial attack
// accelerate(0) - pitch glide
// semitone(12) - how far off in pitch the secondary oscillator is (need not be integer)
// pitch1(1) - filter frequency scaling multiplier, the frequency itself follows the pitch set by "n"
// speed(1)- LFO rate
// lfo(1) - how much the LFO affects the filter frequency
// resonance(0.2) - filter resonance
// voice(0.5) - depends on the individual synth

// a moog-inspired square-wave synth; variable-width pulses with filter frequency modulated by an LFO
// "voice" controls the pulse width (exactly zero or one will make no sound)
(
	SynthDef(\supersquare, {|out, speed=1, decay=0, sustain=1, pan, accelerate, freq,
		voice=0.5, semitone=12, resonance=0.2, lfo=1, pitch1=1|
		var env = EnvGen.ar(Env.pairs([[0,0],[0.05,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -3), timeScale:sustain, doneAction:2);
		var basefreq = freq* Line.kr(1, 1+accelerate, sustain);
		var basefreq2 = basefreq / (2**(semitone/12));
		var lfof1 = min(basefreq*10*pitch1, 22000);
		var lfof2 = min(lfof1 * (lfo + 1), 22000);
		var sound = (0.7 * Pulse.ar(basefreq, voice)) + (0.3 * Pulse.ar(basefreq2, voice));
		sound = MoogFF.ar(
			sound,
			SinOsc.ar(basefreq/64*speed, 0).range(lfof1,lfof2),
			resonance*4);
		sound = sound.tanh * 2;
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
	}).add
);


// a moog-inspired sawtooth synth; slightly detuned saws with triangle harmonics, filter frequency modulated by LFO
// "voice" controls a relative phase and detune amount
(
	SynthDef(\supersaw, {|out, speed=1, decay=0, sustain=1, pan, accelerate, freq,
		voice=0.5, semitone=12, resonance=0.2, lfo=1, pitch1=1|
		var env = EnvGen.ar(Env.pairs([[0,0],[0.05,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -3), timeScale:sustain, doneAction:2);
		var basefreq = freq * Line.kr(1, 1+accelerate, sustain);
		var basefreq2 = basefreq * (2**(semitone/12));
		var lfof1 = min(basefreq*10*pitch1, 22000);
		var lfof2 = min(lfof1 * (lfo + 1), 22000);
		var sound = MoogFF.ar(
			(0.5 * Mix.arFill(3, {|i|  SawDPW.ar(basefreq * ((i-1)*voice/50+1), 0)})) + (0.5 * LFTri.ar(basefreq2, voice)),
			LFTri.ar(basefreq/64*speed, 0.5).range(lfof1,lfof2),
			resonance*4);
		sound = sound.tanh*2;
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
	}).add
);


// a moog-inspired PWM synth; pulses multiplied by phase-shifted pulses, double filtering with an envelope on the second
// "voice" controls the phase shift rate
(
	SynthDef(\superpwm, {|out, speed=1, decay=0, sustain=1, pan, accelerate, freq,
		voice=0.5, semitone=12, resonance=0.2, lfo=1, pitch1=1|
		var env = EnvGen.ar(Env.pairs([[0,0],[0.05,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -3), timeScale:sustain, doneAction:2);
		var env2 = EnvGen.ar(Env.pairs([[0,0.1],[0.1,1],[0.4,0.5],[0.9,0.2],[1,0.2]], -3), timeScale:sustain/speed);
		var basefreq = freq * Line.kr(1, 1+accelerate, sustain);
		var basefreq2 = basefreq / (2**(semitone/12));
		var lfof1 = min(basefreq*10*pitch1, 22000);
		var lfof2 = min(lfof1 * (lfo + 1), 22000);
		var sound = 0.7 * PulseDPW.ar(basefreq) * DelayC.ar(PulseDPW.ar(basefreq), 0.2, Line.kr(0,voice,sustain)/basefreq);
		sound = 0.3 * PulseDPW.ar(basefreq2) * DelayC.ar(PulseDPW.ar(basefreq2), 0.2, Line.kr(0.1,0.1+voice,sustain)/basefreq) + sound;
		sound = MoogFF.ar(sound, SinOsc.ar(basefreq/32*speed, 0).range(lfof1,lfof2), resonance*4);
		sound = MoogFF.ar(sound, min(env2*lfof2*1.1, 22000), 3);
		sound = sound.tanh*5;
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
	}).add
);


// this synth is inherently stereo, so handles the "pan" parameter itself and tells SuperDirt not to mix down to mono
// "voice" scales the comparator frequencies, higher values will sound "breathier"
(
	SynthDef(\supercomparator, {|out, speed=1, decay=0, sustain=1, pan, accelerate, freq,
		voice=0.5, resonance=0.5, lfo=1, pitch1=1|
		var env = EnvGen.ar(Env.pairs([[0,0],[0.05,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -3), timeScale:sustain, doneAction:2);
		var basefreq = freq * Line.kr(1, 1+accelerate, sustain);
		var sound = VarSaw.ar(basefreq, 0, Line.ar(0,1,sustain));
		var freqlist =[ 1.000, 2.188,  5.091,  8.529,  8.950,  9.305, 13.746, 14.653, 19.462, 22.003, 24.888, 25.991,
			26.085, 30.509, 33.608, 35.081, 40.125, 42.023, 46.527, 49.481]**(voice/5);
		sound = Splay.arFill(16, {|i| sound > LFTri.ar(freqlist[i])}, 1);
		sound = MoogFF.ar(
			sound,
			pitch1 * 4 * basefreq + SinOsc.ar(basefreq/64*speed, 0, lfo*basefreq/2) + LFNoise2.ar(1,lfo*basefreq),
			LFNoise2.ar(0,0.1,4*resonance));
		sound = 0.5 * Balance2.ar(sound[0], sound[1], pan*2-1);
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, 0.5, env, {|x| x}));
	}).add
);


// uses the Atari ST emulation UGen with 3 oscillators
// "slide" is for a linear frequency glide that will repeat "speed" times (can be fractional or negative)
// "accelerate" is for an overall glide,
// "pitch2" and "pitch3" control the ratio of harmonics
// "voice" causes variations in the levels of the 3 oscillators
(
	SynthDef(\superchip, {|out, sustain=1, pan, freq, speed=1, slide=0, pitch2=2, pitch3=3, accelerate, voice=0|
		var env, basefreq, sound, va, vb, vc;
		env = EnvGen.ar(Env.linen(0.01, 0.98, 0.01,1,-1), timeScale:sustain, doneAction:2);
		basefreq = freq + wrap2(slide * 100 * Line.kr(-1,1+(2*speed-2),sustain), slide * 100);
		basefreq = basefreq * Line.kr(1, accelerate+1, sustain);
		va = (voice < 0.5) * 15;
		vb = ((2*voice) % 1 < 0.5) * 15;
		vc = ((4*voice) % 1 < 0.5) * 15;
		sound= AY.ar( AY.freqtotone(basefreq), AY.freqtotone(pitch2*basefreq), AY.freqtotone(pitch3*basefreq),
			vola:va, volb:vb, volc:vc)/2;
		sound = tanh(sound)*2;
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
	}).add
);


// digital noise in several flavors with a bandpass filter
// "voice" at 0 is a digital noise for which "n" controls rate, at 1 is Brown+White noise for which "n" controls knee frequency
// "accelerate" causes glide in n, "speed" will cause it to repeat
// "pitch1" scales the bandpass frequency (which tracks "n")
// "slide" works like accelerate on the bandpass
// "resonance" is the filter resonance
(
	SynthDef(\supernoise, {|out, sustain=1, pan, freq, accelerate, slide=0, pitch1=1, speed=1, resonance=0, voice=0|
		var env, basefreq, sound, ffreq, acc;
		env = EnvGen.ar(Env.linen(0.01, 0.98, 0.01,1,-1), timeScale:sustain, doneAction:2);
		acc = accelerate * freq * 4;
		basefreq = freq * 8 + wrap2(acc* Line.kr(-1,1+(2*speed-2), sustain), acc);
		ffreq = basefreq*5*pitch1* Line.kr(1,1+slide, sustain);
		ffreq = clip(ffreq, 60,20000);
		sound = XFade2.ar( LFDNoise0.ar(basefreq.min(22000), 0.5),
			XFade2.ar(BrownNoise.ar(0.5), WhiteNoise.ar(0.5), basefreq.cpsmidi/127),
			2*voice-1);
		sound = HPF.ar(BMoog.ar(sound, ffreq, resonance, 3), 20);
		sound = clip(sound, -1,1) * 0.3;
		OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
	}).add
);

