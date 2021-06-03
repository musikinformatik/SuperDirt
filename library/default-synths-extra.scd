// physical modeling of a vibrating string, using a delay line (CombL) excited by an intial pulse (Impulse)
// To make it a bit richer, I've combined two slightly detuned delay lines
// "accelerate" is used for a pitch glide, and "sustain" changes the envelope timescale
(
	SynthDef(\supermandolin, {|out, sustain=1, pan, accelerate, freq, detune=0.2, speed=1|
		var env = EnvGen.ar(Env.linen(0.002, 0.996, 0.002, 1,-3), timeScale:sustain, doneAction:2);
		var sound = Decay.ar(Impulse.ar(0,0,0.1), 0.1*(freq.cpsmidi)/69) * WhiteNoise.ar;
		var pitch = freq * DirtFreqScale.kr(speed, accelerate, sustain);
		sound = CombL.ar(sound, 0.05, pitch.reciprocal*(1-(detune/100)), sustain)
			+ CombL.ar(sound, 0.05, pitch.reciprocal*(1+(detune/100)), sustain);
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// an example of additive synthesis, building up a gong-like noise from a sum of sine-wave harmonics
// notice how the envelope timescale and amplitude can be scaled as a function of the harmonic frequency
// "voice" provides something like a tone knob, and "decay" adjusts how the harmonics decay
// as in the other SynthDefs, "sustain" affects the overall envelope timescale and "accelerate" for pitch glide
// for a demo, try this in Tidal
// d1 $ n (slow 2 $ fmap (*7) $ run 8) # s "supergong" # decay "[1 0.2]/4" # voice "[0.5 0]/8"
(
	SynthDef(\supergong,{|out, sustain=1, pan, accelerate, freq, voice=0, decay=1, speed=1|
		// lowest modes for clamped circular plate
		var freqlist =[1.000,  2.081,  3.414,  3.893,  4.995,  5.954,  6.819,  8.280,  8.722,  8.882, 10.868, 11.180, 11.754,
			13.710, 13.715, 15.057, 15.484, 16.469, 16.817, 18.628]**1.0;
		var tscale = 100.0 / freq / (freqlist**(2-clip(decay,0,2)));
		var ascale =freqlist**clip(voice,0,4);
		var sound = Mix.arFill(15, {arg i; EnvGen.ar(Env.perc(0.01*tscale[i], 0.5*tscale[i], 0.2*ascale[i] ), timeScale:sustain*5)
			* SinOsc.ar(freq * freqlist[i] * DirtFreqScale.kr(speed, accelerate, sustain))});
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan))
	}).add
);


// hooking into a nice synth piano already in supercollider
// uses the "velocity" parameter to affect how hard the keys are pressed
// "sustain" controls envelope and decay time
(
	SynthDef(\superpiano,{|out, sustain=1, pan, velocity=1, detune=0.1, muffle=1, stereo=0.2, freq=440, accelerate=0, speed=1|
		var env = EnvGen.ar(Env.linen(0.002, 0.996, 0.002, 1,-3), timeScale:sustain, doneAction:2);
		// the +0.01 to freq is because of edge case rounding internal to the MdaPiano synth
		var sound = MdaPiano.ar(freq*DirtFreqScale.kr(speed, accelerate, sustain)+0.01,
			vel:velocity*100, hard:0.8*velocity, decay:0.1*sustain,
			tune:0.5, random:0.05, stretch:detune, muffle:0.8*muffle, stereo:stereo);
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);

// waveguide mesh, hexagonal drum-like membrane
(
	SynthDef(\superhex,{|out, rate=1, sustain=1, pan, freq, accelerate, speed=1|
		var env = EnvGen.ar(Env.linen(0.02, 0.96, 0.02, 1,-3), timeScale:sustain, doneAction:2);
		var tension = 0.05*freq/400 * DirtFreqScale.kr(speed, accelerate, sustain);
		var loss = 1.0 - (0.01 * rate / freq);
		var sound = MembraneHexagon.ar(Decay.ar(Impulse.ar(0,0,1), 0.01), tension, loss);
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// Kick Drum using Rumble-San's implementation as a starting point
// http://blog.rumblesan.com/post/53271713518/drum-sounds-in-supercollider-part-1
// "n" controls the kick frequency in a nonstandard way
// "sustain" affects overall envelope timescale, "accelerate" sweeps the click filter freq,
// "pitch1" affects the click frequency, and "decay" changes the click duration relative to the overall timescale
(
	SynthDef(\superkick, {|out, sustain=1, pan, accelerate, n, pitch1=1, decay=1, speed=1|
		var env, sound, dur, clickdur;
		env = EnvGen.ar(Env.linen(0.01, 0, 0.5, 1, -3), timeScale:sustain, doneAction:2);
		sound = SinOsc.ar((n - 25.5).midicps);
		clickdur = 0.02*sustain*decay;
		sound = sound + (LPF.ar(WhiteNoise.ar(1), 1500*pitch1*DirtFreqScale.kr(speed, accelerate, clickdur) ) * Line.ar(1, 0, clickdur));
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// A vaguely 808-ish kick drum
// "n" controls the chirp frequency, "sustain" the overall timescale, "rate" the filter sweep speed,
// and "voice" the sinewave feedback
(
	SynthDef(\super808, {|out, rate=1, sustain=1, pan, voice=0, n, speed=1, accelerate|
		var env, sound, freq;
		n = ((n>0)*n) + ((n<1)*3);
		freq = (n*10).midicps * DirtFreqScale.kr(speed, accelerate, sustain);
		env = EnvGen.ar(Env.linen(0.01, 0, 1, 1, -3), timeScale:sustain, doneAction:2);
		sound = LPF.ar(SinOscFB.ar(XLine.ar(freq.expexp(10, 2000, 1000, 8000), freq, 0.025/rate), voice), 9000);
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// Hi-hat using Rumble-San's implementation as a starting point
// http://blog.rumblesan.com/post/53271713518/drum-sounds-in-supercollider-part-1
// using "n" in a weird way to provide some variation on the frequency
// "sustain" affects the overall envelope rate, "accelerate" sweeps the filter
(
	SynthDef(\superhat, {|out, sustain=1, pan, accelerate, n, speed=1|
		var env, sound, freq;
		env = EnvGen.ar(Env.linen(0.01, 0, 0.3, 1, -3), timeScale:sustain, doneAction:2);
		freq = 2000 * DirtFreqScale.kr(speed, accelerate, sustain) * (n/5 + 1).wrap(0.5,2);
		sound = HPF.ar(LPF.ar(WhiteNoise.ar(1), 3*freq), freq);
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// Snare drum using Rumble-San's implementation as a starting point
// http://blog.rumblesan.com/post/53271713909/drum-sounds-in-supercollider-part-2
// again using "n" for some variation on frequency, "decay" for scaling noise duration relative to tonal part
// "sustain" for overall timescale, "accelerate" for tonal glide
(
	SynthDef(\supersnare, {|out, sustain=1, pan, accelerate, n, decay=1, speed=1|
		var env = EnvGen.ar(Env.linen(0.01, 0, 0.6, 1, -3), timeScale:sustain, doneAction:2);
		var freq = 100 * DirtFreqScale.kr(speed, accelerate, sustain) * (n/5+1).wrap(0.5,2);
		var sound = LPF.ar(Pulse.ar(freq), Line.ar(1030, 30, 0.2*sustain))
			+ (BPF.ar(HPF.ar(WhiteNoise.ar(1), 500), 1500) * Line.ar(1, 0, 0.2*decay));
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// Hand clap using Rumble-San's implementation as a starting point
// http://blog.rumblesan.com/post/53271713909/drum-sounds-in-supercollider-part-2
// "delay" controls the echo delay, "rate" will affect the decay time, "n" changes how spread is calculated
// "pitch1" will scale the bandpass frequency, and "sustain" the overall timescale
(
	SynthDef(\superclap, {|out, rate=1, sustain=1, pan, n, delay=1, pitch1=1 |
		var env, sound;
		var spr = 0.005 * delay;
		env = EnvGen.ar(Env.linen(0.01, 0, 0.6, 1, -3), timeScale:sustain, doneAction:2);
		sound = BPF.ar(LPF.ar(WhiteNoise.ar(1), 7500*pitch1), 1500*pitch1);
		sound = Mix.arFill(4, {arg i; sound * 0.5 * EnvGen.ar(Env.new([0,0,1,0],[spr*(i**(n.clip(0,5)+1)),0,0.04/rate]))});
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
	}).add
);


// a controllable synth siren, defaults to 1 second, draw it out with "sustain"
(
	SynthDef(\supersiren, {|out, sustain=1, pan, freq, accelerate, speed=1|
		var env, sound;
		freq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
		env = EnvGen.ar(Env.linen(0.05, 0.9, 0.05, 1, -2), timeScale:sustain, doneAction:2);
		sound = VarSaw.ar(freq * (1.0 + EnvGen.kr(Env.linen(0.25,0.5,0.25,3,0), timeScale:sustain, doneAction:2)),
			0, width:Line.kr(0.05,1,sustain));
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
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
// rate(1)- LFO rate
// lfo(1) - how much the LFO affects the filter frequency
// resonance(0.2) - filter resonance
// voice(0.5) - depends on the individual synth

// a moog-inspired square-wave synth; variable-width pulses with filter frequency modulated by an LFO
// "voice" controls the pulse width (exactly zero or one will make no sound)
(
	SynthDef(\supersquare, {|out, rate=1, decay=0, sustain=1, pan, accelerate, freq,
		voice=0.5, semitone=12, resonance=0.2, lfo=1, pitch1=1, speed=1|
		var env = EnvGen.ar(Env.pairs([[0,0],[0.05,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -3), timeScale:sustain, doneAction:2);
		var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
		var basefreq2 = basefreq / (2**(semitone/12));
		var lfof1 = min(basefreq*10*pitch1, 22000);
		var lfof2 = min(lfof1 * (lfo + 1), 22000);
		var sound = (0.7 * Pulse.ar(basefreq, voice)) + (0.3 * Pulse.ar(basefreq2, voice));
		sound = MoogFF.ar(
			sound,
			SinOsc.ar(basefreq/64*rate, 0).range(lfof1,lfof2),
			resonance*4);
		sound = sound.tanh * 2;
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
	}).add
);


// a moog-inspired sawtooth synth; slightly detuned saws with triangle harmonics, filter frequency modulated by LFO
// "voice" controls a relative phase and detune amount
(
	SynthDef(\supersaw, {|out, rate=1, decay=0, sustain=1, pan, accelerate, freq,
		voice=0.5, semitone=12, resonance=0.2, lfo=1, pitch1=1, speed=1|
		var env = EnvGen.ar(Env.pairs([[0,0],[0.05,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -3), timeScale:sustain, doneAction:2);
		var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
		var basefreq2 = basefreq * (2**(semitone/12));
		var lfof1 = min(basefreq*10*pitch1, 22000);
		var lfof2 = min(lfof1 * (lfo + 1), 22000);
		var sound = MoogFF.ar(
			(0.5 * Mix.arFill(3, {|i|  SawDPW.ar(basefreq * ((i-1)*voice/50+1), 0)})) + (0.5 * LFTri.ar(basefreq2, voice)),
			LFTri.ar(basefreq/64*rate, 0.5).range(lfof1,lfof2),
			resonance*4);
		sound = sound.tanh*2;
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
	}).add
);


// a moog-inspired PWM synth; pulses multiplied by phase-shifted pulses, double filtering with an envelope on the second
// "voice" controls the phase shift rate
(
	SynthDef(\superpwm, {|out, rate=1, decay=0, sustain=1, pan, accelerate, freq,
		voice=0.5, semitone=12, resonance=0.2, lfo=1, pitch1=1, speed=1|
		var env = EnvGen.ar(Env.pairs([[0,0],[0.05,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -3), timeScale:sustain, doneAction:2);
		var env2 = EnvGen.ar(Env.pairs([[0,0.1],[0.1,1],[0.4,0.5],[0.9,0.2],[1,0.2]], -3), timeScale:sustain/rate);
		var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
		var basefreq2 = basefreq / (2**(semitone/12));
		var lfof1 = min(basefreq*10*pitch1, 22000);
		var lfof2 = min(lfof1 * (lfo + 1), 22000);
		var sound = 0.7 * PulseDPW.ar(basefreq) * DelayC.ar(PulseDPW.ar(basefreq), 0.2, Line.kr(0,voice,sustain)/basefreq);
		sound = 0.3 * PulseDPW.ar(basefreq2) * DelayC.ar(PulseDPW.ar(basefreq2), 0.2, Line.kr(0.1,0.1+voice,sustain)/basefreq) + sound;
		sound = MoogFF.ar(sound, SinOsc.ar(basefreq/32*rate, 0).range(lfof1,lfof2), resonance*4);
		sound = MoogFF.ar(sound, min(env2*lfof2*1.1, 22000), 3);
		sound = sound.tanh*5;
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
	}).add
);


// "voice" scales the comparator frequencies, higher values will sound "breathier"
(
	SynthDef(\supercomparator, {|out, rate=1, decay=0, sustain=1, pan, accelerate, freq,
		voice=0.5, resonance=0.5, lfo=1, pitch1=1, speed=1|
		var env = EnvGen.ar(Env.pairs([[0,0],[0.05,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -3), timeScale:sustain, doneAction:2);
		var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
		var sound = VarSaw.ar(basefreq, 0, Line.ar(0,1,sustain));
		var freqlist =[ 1.000, 2.188,  5.091,  8.529,  8.950,  9.305, 13.746, 14.653, 19.462, 22.003, 24.888, 25.991,
			26.085, 30.509, 33.608, 35.081, 40.125, 42.023, 46.527, 49.481]**(voice/5);
		sound = Splay.arFill(16, {|i| sound > LFTri.ar(freqlist[i])}, 1);
		sound = MoogFF.ar(
			sound,
			pitch1 * 4 * basefreq + SinOsc.ar(basefreq/64*rate, 0, lfo*basefreq/2) + LFNoise2.ar(1,lfo*basefreq),
			LFNoise2.ar(0,0.1,4*resonance));
		Out.ar(out, DirtPan.ar(0.5*sound, ~dirt.numChannels, pan, env));
	}).add
);


// uses the Atari ST emulation UGen with 3 oscillators
// "slide" is for a linear frequency glide that will repeat "rate" times (can be fractional or negative)
// "accelerate" is for an overall glide,
// "pitch2" and "pitch3" control the ratio of harmonics
// "voice" causes variations in the levels of the 3 oscillators
(
	SynthDef(\superchip, {|out, sustain=1, pan, freq, rate=1, slide=0, pitch2=2, pitch3=3, accelerate, voice=0, speed=1|
		var env, basefreq, sound, va, vb, vc;
		env = EnvGen.ar(Env.linen(0.01, 0.98, 0.01,1,-1), timeScale:sustain, doneAction:2);
		basefreq = freq + wrap2(slide * 100 * Line.kr(-1,1+(2*rate-2),sustain), slide * 100);
		basefreq = basefreq * DirtFreqScale.kr(speed, accelerate, sustain);
		va = (voice < 0.5) * 15;
		vb = ((2*voice) % 1 < 0.5) * 15;
		vc = ((4*voice) % 1 < 0.5) * 15;
		sound= AY.ar( AY.freqtotone(basefreq), AY.freqtotone(pitch2*basefreq), AY.freqtotone(pitch3*basefreq),
			vola:va, volb:vb, volc:vc)/2;
		sound = tanh(sound)*2;
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
	}).add
);


// digital noise in several flavors with a bandpass filter
// "voice" at 0 is a digital noise for which "n" controls rate, at 1 is Brown+White noise for which "n" controls knee frequency
// "accelerate" causes glide in n, "rate" will cause it to repeat
// "pitch1" scales the bandpass frequency (which tracks "n")
// "slide" works like accelerate on the bandpass
// "resonance" is the filter resonance
(
	SynthDef(\supernoise, {|out, sustain=1, pan, freq, accelerate, slide=0, pitch1=1, rate=1, resonance=0, voice=0|
		var env, basefreq, sound, ffreq, acc;
		env = EnvGen.ar(Env.linen(0.01, 0.98, 0.01,1,-1), timeScale:sustain, doneAction:2);
		acc = accelerate * freq * 4;
		basefreq = freq * 8 + wrap2(acc* Line.kr(-1,1+(2*rate-2), sustain), acc);
		ffreq = basefreq*5*pitch1* Line.kr(1,1+slide, sustain);
		ffreq = clip(ffreq, 60,20000);
		sound = XFade2.ar( LFDNoise0.ar(basefreq.min(22000), 0.5),
			XFade2.ar(BrownNoise.ar(0.5), WhiteNoise.ar(0.5), basefreq.cpsmidi/127),
			2*voice-1);
		sound = HPF.ar(BMoog.ar(sound, ffreq, resonance, 3), 20);
		sound = clip(sound, -1,1) * 0.3;
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
	}).add
);


// tuning fork
// from my own experimentation and from "On the acoustics of tuning forks", Rossing Russell and Brown
(
SynthDef(\superfork, {|out, sustain=1, pan, freq, accelerate=0, speed=1|
	var sound, env;
	freq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
	env = EnvGen.ar(Env.linen(0.001, 0.998, 0.001), timeScale:sustain, doneAction:2);
	sound = 0.2 * SinOsc.ar([1.0, 6.1, 16.7, 20.1] * freq) * XLine.ar([0.3, 1, 1.3, 2], [1e-4, 1e-7, 1e-6, 1e-7], sustain*[4,4,0.5,0.333]);
	Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add
);


// hammond B3 sim
// freq adjustments courtesy Tom Wiltshire (electricdruid.net)
// drawbar settings selectable with "voice" and from many public domain sources,
// Google "Hammond drawbar settings" and add your own in the big SelectX block
// "perc" "percf" and "decay" are an attempt at the percussion, no idea if it sounds at all reasonable
// vintage Hammonds had percf as 2 or 3 (switchable), two perc levels (maybe roughly 0.7 and 1.2?),
// and two decay options (roughly 0 and maybe 1ish?)
// "vibrato", "vrate", "perc", "percf" are all new params you'll need to define in Tidal if you want to change them
(
SynthDef(\superhammond, {|out, sustain=1, decay=0, pan, freq, vibrato=0.5, vrate=7,
	voice=0, perc=0, percf=2, accelerate=0, speed=1|
	var freqs, amps, sound, click, env, ampscale, attrel;
	attrel = (sustain/2).clip(0,0.005);
	freq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
	env = EnvGen.ar(Env.linen(attrel, sustain-(2*attrel), attrel), doneAction:2);
	freqs = [0.5, 1.4988, 1, 2, 2.9976, 4, 5.0409, 5.9953, 8] * freq;
	freqs = 2**(freqs < 63) * freqs; // fold up bottom register
	freqs = freqs / (2**(freqs > 6000)); // fold down high harmonics
	freqs = freqs / (2**(freqs > 6000)); // do it again for the really high notes
	amps = SelectX.kr(voice, #[
		[1, 4, 5, 4, 3, 1, 0, 0, 0], // 0: bass violin 16'
		[0, 0, 8, 0, 4, 0, 0, 0, 0], // 1: tibia 8'
		[0, 7, 8, 1, 2, 0, 0, 0, 0], // 2: bassoon 8'
		[0, 0, 7, 8, 8, 8, 8, 7, 2], // 3: french trumpet 8'
		[4, 0, 5, 5, 4, 5, 3, 3, 6], // 4: string ensemble
		[8, 8, 5, 3, 2, 4, 5, 8, 8], // 5: Blues
		[8, 8, 8, 0 ,0, 0, 0, 0, 3], // 6: Jazz 1
		[8, 8, 8, 8, 8, 8, 8, 8, 8], // 7: Full Shout
		[8, 0, 0, 0, 0, 0, 8, 8, 8], // 8: Bro' Jack
		[0, 0, 8, 8, 0, 0, 0, 0, 0]  // 9: Jazz 2
	]);
	amps = amps - [0, 0, 0, 0, 0, 0, 0.5, 1, 1.5]; // damp brilliance a bit
	amps = 2**(amps-8);
	click = WhiteNoise.ar(1) * XLine.ar(1,1e-6, 0.1);
	sound = 0.5 * Mix.ar( SinOsc.ar(freqs*(2*click+1), (2pi ! 9).rand, amps/amps.sum) );
	sound = perc * 0.5 * SinOsc.ar(freq*percf, 2pi.rand) * XLine.ar(1,1e-6,2*decay+1) + sound;
	sound = sound + BAllPass.ar(sound, 1000*LFTri.kr(vrate,0,vibrato/2,1));
	Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add
);


// vibraphone simulation, adapted with some help from Kevin Larke's thesis Real Time Vibraphone Pitch and Timbre Classification
// "decay" - use larger values to damp higher harmonics (default 0)
// "velocity" - higher velocity will brighten the sound a bit (default 1)
// "accelerate" - for a linear pitch bend
// "modamp" - amplitude of the tremolo (0-2 is OK, default 1)
// "modfreq" - frequency of the tremolo (default 7)
// "detune" - adjusts a high harmonic to give the sound a different character
(
SynthDef(\supervibe, {|out, sustain=1, decay=0, pan, freq, accelerate=0, velocity=1,
	modamp=1, modfreq=7.0, detune=0, speed=1|
	// most envelope shaping is done with XLines later, this envelope is just to clean up overall
	var env = EnvGen.ar(Env.linen(0.001, 0.998, 0.001), timeScale:sustain, doneAction:2);
	var sound, mod, freqs, hifreqs, decays;
	freq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
	freqs = freq * [1, 4, 10, 13.75 + detune];
	hifreqs = freq * [19.2, 20, 21.2];
	mod = SinOsc.kr(modfreq, Rand(0,2pi)).range(1-([0.5,0.3,0.3,0.5]*modamp),1);
	sound = 0.3 * [1, 1.1*velocity, 0.6*velocity*velocity, 0.5*velocity] * SinOsc.ar(freqs);
	decays = [1, 0.7*exp(-1.0*decay), 0.5*exp(-1.0*decay), 0.4*exp(-1.0*decay)];
	sound = XLine.ar(1e-6, 1, 1/freqs) * XLine.ar(1, 1e-6, decays*4*sustain) * sound * mod; // main attacks and decays
	sound = (XLine.ar(0.3*(velocity+1e-6),1e-6,0.02) * SinOsc.ar(hifreqs)).sum + sound.sum; // hi frequency onset
	Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add
);


// Hoover, adapted from Wouter Snoei's
// http://superdupercollider.blogspot.com/2009/06/more-dominator-deconstruction.html
// "slide" is used for the amount of initial pitch glide, positive slides up in pitch, negative slides down
// also responds to "decay" for a different envelope shape and "accelerate" for constant pitch glide
// uncomment the two lines with "rrand" for a different every time you evaulate it
(
SynthDef(\superhoover, {|out, sustain=1, decay=0, pan, freq, accelerate=0, slide=0, speed=1|
	var env = EnvGen.ar(Env.pairs([[0,0],[0.03,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -1), timeScale:sustain, doneAction:2);
	var pwm, mix, fglide;
	fglide = EnvGen.ar(Env.perc(0.05, 0.3, 1, \lin), timeScale:sustain) * (-1*slide/4) + 1;
	freq = freq * fglide * DirtFreqScale.kr(speed, accelerate, sustain);
	freq = SinOsc.kr( [2.94, 3.0, 3.07], [3.0, 5.5, 1.2] ).exprange(0.995, 1.005) * freq;
	// freq = SinOsc.kr( {2.9 rrand: 3.1}!3, {2pi.rand}!3 ).exprange(0.995, 1.005) * freq;
	pwm = SinOsc.kr( [1.3, 2.9, 4.4] ).range(1/8, 7/8);
	// pwm = SinOsc.kr( {1.0 rrand: 5.0}!3 ).range(1/8, 7/8);
	mix = ([1,0.9,1.1]*LFSaw.ar(freq*[0.25, 0.5, 1], [1, 1.01, 1.02]).range(0,1) * (1 - LFPulse.ar(freq*[0.5,1,2], [0,0,0], pwm))).sum * 0.15;
	mix = mix + LFPar.ar(freq * 0.25, 0, 0.1).sum;
	mix = BPeakEQ.ar(mix, 6000, 1, 3);
	mix = BPeakEQ.ar(mix, 3500, 1, 6);
	mix = mix.dup + CombC.ar(mix.dup, 1/200, SinOsc.kr(3, [0.5pi, 1.5pi]).range(1/300, 1/200), 0);
	Out.ar(out, DirtPan.ar(1.4*mix, ~dirt.numChannels, pan, env));
}).add
);


// phased saws
// "decay" and "accelerate" used as in some synths above, for envelope shaping and pitch bend, respectively
// "slide" here is how fast it moves through the phase (default 1)
// "detune" is for oscillator detuning and defaults to 1
(
SynthDef(\superzow, {|out, sustain=1, pan, accelerate, freq, decay=0, slide=1, detune=1, speed=1|
	var env = EnvGen.ar(Env.pairs([[0,0],[0.07,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -1), timeScale:sustain, doneAction:2);
	var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
	var sound = VarSaw.ar(basefreq, 0, Line.ar(0,0.5,sustain*20/slide));
	var sound2 = VarSaw.ar(basefreq*(detune/100+1), 0, Line.ar(0,0.5,sustain*20/slide));
	var sound3 = VarSaw.ar(basefreq*(-1*detune/100+1), 0, Line.ar(0,0.5,sustain*20/slide));
	sound = sound - DelayN.ar(sound2,0.2, Line.ar(0,1,5*sustain/slide)/basefreq)
	  + DelayN.ar(sound3,0.2, Line.ar(0,1,20*sustain/slide)/basefreq);
	Out.ar(out, DirtPan.ar(sound/2, ~dirt.numChannels, pan, env));
}).add
);


// impulse noise with a fadein/out
(
SynthDef(\superstatic, {|out, sustain=1, pan, freq, accelerate=0, speed=1 |
	var sound;
	var env = EnvGen.ar(Env.sine(1, 0.5), timeScale:sustain, doneAction:2);
	freq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
	sound = Dust.ar(freq*40) > 0.5;
	sound = Pulse.ar(freq*sound*4,0.5,0.5);
	Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add
);


// from synthdef.art
// fragment: 2018-08-16
// responds to accelerate (for pitch glide)
//                    detune (in Hz, but even small values are quite noticable)
//                    voice (changes harmonics)
//                    rate  (impulse trigger rate)
(
SynthDef(\supergrind, {|out, pan, freq, sustain, accelerate, detune=0, voice=0, rate=1, speed=1|
	var env, trig, loop;
	freq = (freq * DirtFreqScale.kr(speed, accelerate, sustain))/2;
	env = EnvGen.ar(Env.linen(0.1, 0.8, 0.1), timeScale:sustain, doneAction:2);
	trig = Impulse.kr(rate * Duty.kr(1, 0, Dseq(0.25 ! 3 ++ [2], inf)));
	loop = LocalIn.ar;
	loop = loop + Impulse.ar(SinOsc.ar(1/4, 0, freq/2, (voice+1.0)*freq));
	loop = Mix.ar(DelayC.ar(loop + trig, 1, 1/(2*freq+[detune, -1.0*detune])-ControlDur.ir))/2.0;
	LocalOut.ar(LeakDC.ar(loop).tanh);
	loop = loop + DelayC.ar(loop, 0.2, SinOsc.ar(1, 0, 1e-3, 0.1));
	loop = GVerb.ar(sin(loop + (8*trig)*4)).sin + loop;
	Out.ar(out, DirtPan.ar(0.3*loop, ~dirt.numChannels, pan, env));
}).add;
);

// from synthdef.art
// #nightofprimes
// responds to accelerate (for pitch glide)
//                    detune (fractional)
//                    voice (some subtle shaping and reverb changing)
//                    rate  (impulse trigger rate)
(
SynthDef(\superprimes, {|out, pan, freq, sustain, accelerate, rate=1, detune=0, voice=0, speed=1|
	var env, sound, primes, trig, phase;
	freq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
	env = EnvGen.ar(Env.linen(0.1, 0.6, 0.3), timeScale:sustain, doneAction:2);
	primes = [2, 3, 5, 7, 11, 13, 17, 19, 23];
	trig = Impulse.ar(30.0/primes/sustain * rate);
	phase = Phasor.kr(trig, 1.0/primes/ControlRate.ir);
	sound = SinOsc.ar(freq * (1..primes.size)*[1+(detune/12),1-(detune/12)] / 2.0, phase)
    	* LPF.ar(Decay.ar(trig, (primes+3)*sustain/10), voice.linexp(0,2,30,18000));
	sound = GVerb.ar(sound.softclip, 10*voice.linexp(0,5,1,0.01), 10).tanh;
	sound = SplayAz.ar(primes.size, sound.flat, center:LFNoise2.kr(sustain).range(0,primes.size-1));
	Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add;
);

// from synthdef.art
// #wavemechanics
// responds to accelerate (for pitch glide)
//                    detune (for pitch randomization)
//                    voice (to color/whiten the noise)
//                    resonance (affects reverberation)
(
SynthDef(\superwavemechanics, {|out, pan, freq, sustain, accelerate, detune=0, voice=0, resonance=0, speed=1|
	var env, sound, i, r, d, bwr, sz;
	freq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
	env = EnvGen.ar(Env.sine(1.0), timeScale:sustain, doneAction:2);
	i = TIRand.kr(0, 3, Impulse.kr(sustain/8).dup(8));
	r = [3,5,8,9]/8;
	detune = min(detune, 1.5);
	d = Rand(1.6*i - detune, 1.7*i + detune).round(0.25);
	sound = Resonz.ar(WhiteNoise.ar(0.5), freq * r * d, 0.01 + voice.linexp(0,1,1e-3,1));
	sound = HPF.ar(Limiter.ar(55 * GVerb.ar(sound, resonance.linexp(0,1,99,0.1),10) ), 30).sanitize;
	Out.ar(out, DirtPan.ar(sound.flat, ~dirt.numChannels, pan, env));
}).add;
);

// feedback PWM
// can use "accelerate" "voice" and "detune" parameters
// try `d1 $ s "supertron" # octave 3 # accelerate "0.2"`
(
SynthDef(\supertron, {|out, pan, freq, sustain, voice, detune, accelerate, speed=1|
	var sound, aenv, s1, s2;
	aenv = EnvGen.ar(Env.linen(0.05, 0.85, 0.1, 1, 'lin'), timeScale:sustain, doneAction:2);
	freq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
	sound = LocalIn.ar(1);
	sound = Mix.ar( Pulse.ar(freq+[1+detune,-1-detune], RLPF.ar(sound, freq/6.1, 1.5).range(0,1-(voice/1.5))) );
	sound = LeakDC.ar(sound);
	LocalOut.ar(sound);
	Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, aenv))
}).add;
);

// Vaguely Reese-like synth
// can use "accelerate" "voice" and "detune" parameters
(
SynthDef(\superreese,  {|out, pan, freq, sustain, accelerate, detune=0, voice=0, speed=1|
	var sound;
	var env = EnvGen.ar(Env.linen(0.05, 0.8, 0.15), timeScale:sustain, doneAction:2);
	var q1 = voice.linlin(0,2, 3.0, 0.5);
	var q2 = voice.linlin(0,2, 2.0, 7.0);
	freq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
	sound = Splay.ar( VarSaw.ar(freq*[-1*detune/100+0.99,detune/100+1.01], [0.7,0.5], [0.01,0.02]), 0.2, 1, levelComp:false );
	sound = RLPF.ar(sound, freq*10, 1.0/q1);
	sound = sound.clip2(1.0/5.0)* 5.0;
	sound = 0.35*RLPF.ar(sound, freq*20, 1.0/q2);
	Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add;
);

// 6-op FM synth (DX7-like)
//
// Works a bit different from the original DX7.  Instead of algorithms, you set the amount
// of modulation every operator receives from other operators and itself (feedback), virtually
// providing an endless number of possible combinations (algorithms).
//
// Responds to
//   voice (preset number: [0] is user-defined; [1-5] are randomly generated presets).
//   lfofreq (overall pitch modulation frequency)
//   lfodepth (overall pitch modulation amplitude)
//
// Each operator responds to
//   amp (operator volume - becomes carrier)
//   ratio (frequency ratio)
//   detune (in Hz)
//   eglevel[1-4] (4 envelope generator levels)
//   egrate[1-4] (4 envelope generator rates)
//
// The syntax for operator arguments is <argumentName + opIndex>[modulatorIndex | egIndex]
//
// For example:
// amp1 1      (op1 as carrier with full volume)
// ratio2 2.3  (op2 frequency ratio)
// mod11 0.5   (op1 feedback)
// mod12 0.78  (op1 modulation amount by op2)
// detune1 0.2 (op1 detune)
// eglevel12 0.1  (op1 EG level2)
// egrate11 0.01  (op1 EG rate1) -- WARNING: higher values go FASTER!
(
SynthDef(\superfm, {
	var sustain = \sustain.kr(1);
	var lfofreq = \lfofreq.kr(1);
	var lfodepth = \lfodepth.kr(0);
	var freq = \freq.kr(440);
	var tremolo = 1 + (LFTri.kr(lfofreq) * lfodepth);
	var out = \out.kr(0);
	var pan = \pan.kr(0);
	var voice = \voice.kr(0);
	// overall envelope
	var env = EnvGen.ar(Env.linen(0.01, 0.98, 0.01, 1, -3), timeScale:sustain, doneAction:2);
	// operator output levels
	var amps = Array.fill(6, { |i| (\amp++(i+1)).asSymbol.kr(1)});
	// operator frequency ratios
	var ratios = Array.fill(6, {|i| (\ratio++(i+1)).asSymbol.kr(1)});
	// operator frequency detuners
	var detunes = Array.fill(6, {|i| (\detune++(i+1)).asSymbol.kr(rand2(0.1))});
	// feedback -- for presets only
	var feedback = \feedback.kr(0.0);
	// operator envelopes
	var eglevels = Array.fill(6, {|i|
		Array.fill(4, { |n| (\eglevel++(i+1)++(n+1)).asSymbol.kr(1) })
	});
	var egrates = Array.fill(6, {|i| [
		// Supercollider envelopes use seconds for the durations of segments.
		// So higher values mean transitions are slower.
		// DX7s envelopes use rates, which is the inverse of time, 1/time.
		// Higher values in DX7 mean transitions are faster.
		max(0.1 / ((\egrate++(i+1)++1).asSymbol).ir(10), 0.001),
		max(0.1 / ((\egrate++(i+1)++2).asSymbol).ir(0.3), 0.001),
		max(0.1 / ((\egrate++(i+1)++3).asSymbol).ir(0.1), 0.001),
		max(0.1 / ((\egrate++(i+1)++4).asSymbol).ir(0.1), 0.001),
	]});
	// modulation matrix
	var mods = Array.fill2D(6, 6, { |r, c|
		(\mod++(r+1)++(c+1)).asSymbol.kr(0) * if(r == c, feedback, 1)
	});
	var presets = SelectX.kr(voice, [
		[ // user-defined
			ratios,	detunes, amps, eglevels, egrates, mods,
		],
	] ++
	// randomly generated presets
	Array.fill(5, { [
		// ratios
		Array.fill(6, {
			[0.25, 0.5, 1, 2, 3, 4, 5, 6, 7, 11.rand + 1, 13.rand + 1, 15.rand + 1].wchoose(
				[1, 2, 8, 4, 3, 0.5, 0.5, 0.5, 0.5, 0.25, 0.25, 0.25].normalizeSum)
		}),
		// detunes
		Array.fill(6, { rand2(7) }),
		// amps
		Array.fill(6, { 1.0.rand * 0.5.coin.asInteger }),
		// EG levels
		Array.fill2D(6, 4, {1.0.rand}),
		// EG rates
		Array.fill2D(6, 4, {1.0.rand}),
		// mods
		Array.fill2D(6, 6, {|r,c| 1.0.rand * 0.25.coin.asInteger * if(r == c, feedback, 1)}),
	]})
	);

	var envs = Array.fill(6, { |i|
		EnvGen.kr(
			Env.new(
				// EG levels
				[0]++Array.fill(4, { |n| presets[3][i][n] }),
				// EG rates
				Array.fill(4, { |n| presets[4][i][n] })
			),
			timeScale:sustain,
		);
	});

	var ctls = Array.fill(6, { |i|
		[freq * tremolo * presets[0][i] + presets[1][i], 0, envs[i]]
	});

	var sound = FM7.ar(ctls, presets[5]) * amps;
	sound = Mix.ar(sound) * (-15.dbamp);
	Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add;
);

(
// DrumSynths SC Example - SOS Drums by Renick Bell, renick@gmail.com
// recipes from Gordon Reid in his Sound on Sound articles
// SOSkick — http:www.soundonsound.com/sos/jan02/articles/synthsecrets0102.asp
// increase pitch1 and voice for interesting electronic percussion
// Adapted to SuperDirt by Aleksandr Yakunichev, hi@ya.codes
//
// midinote – controls the root note of the kick
// pitch1 - controls modulation frequency in Hz (min: 0, max: SampleRate.ir / 2)
// voice - controls modulation input phase in radians (min: 0, max: your sanity)
// pitch2 - controls WhiteNoise amplitude (min: 0, max: 1)
// speed - controls WhiteNoise sweep (min: 0, max: 1)
SynthDef(\soskick, { |out, pan, freq = 65, pitch1 = 0, speed = 0.3, voice = 1, sustain = 1, pitch2 = 0.00|
  var beater, source, env;

  env = Env.perc(0.005, sustain).ar(Done.freeSelf);

  source = Line.ar(freq * 2, freq, 0.02);
  source = PMOsc.ar(source, pitch1, voice);
  source = LPF.ar(source, 1000);

  beater = WhiteNoise.ar(pitch2.clip);
  beater = HPF.ar(beater, 500);
  beater = LPF.ar(beater, XLine.ar(6000, 500, speed.clip * 0.1));
  beater = beater * Env.perc.ar;

  Out.ar(out, DirtPan.ar((source + beater) * 3.dbamp, ~dirt.numChannels, pan, env));
},
metadata: (
  credit: "Renick Bell",
  category: \drums,
  tags: [\pitched, \bass, \sos]
)).add;
);

(
// Retrieved from http://sccode.org/1-5aD
// DrumSynths SC Example - SOS Drums by Renick Bell, renick@gmail.com
// Recipes from Gordon Reid in his Sound on Sound articles
// SOShats — http:www.soundonsound.com/sos/Jun02/articles/synthsecrets0602.asp
// Modified by Bruno Ruviaro and Josh Mitchell 8/19
// Adapted to SuperDirt by Aleksandr Yakunichev, hi@ya.codes
//
// resonance – bandpass filter resonance value (min: 0, max: 1)
// pitch1 - oscillator modulation in radians (min: 0, max: SampleRate.ir / 2)
SynthDef(\soshats, {
  arg out = 0, pan = 0, freq = 220, pitch1 = 238.5, resonance = 1, sustain = 0.5;
  var source, envelope, bpf, hpf;

  source = Mix(PMOsc.ar(Pulse.ar(freq), freq * [1.34, 2.405, 3.09, 1.309], pitch1 * [1, 0.22, 0.014, 0.0038]));

  bpf = BPF.ar(
    source,
    XLine.kr(15000, 9000, sustain),
    Clip.ir(resonance, 0, 1),
    Env.perc(0.005, sustain, curve: -4).ar
  );

  hpf = HPF.ar(
    source,
    XLine.kr(9000, 12000, sustain),
    Env.perc(0.005, sustain, curve: -4).ar
  );

  envelope = Env.perc(0.005, sustain).ar(Done.freeSelf);

  Out.ar(out, DirtPan.ar((bpf + hpf) * (-5).dbamp, ~dirt.numChannels, pan, envelope));
},
metadata: (
  credit: "Renick Bell",
  category: \drums,
  tags: [\pitched, \hihats, \sos]
)).add;
);

(
// Retrieved from http:sccode.org/1-5aD
// DrumSynths SC Example - SOS Drums by Renick Bell, renick_at_gmail.com
// recipes from Gordon Reid in his Sound on Sound articles
// SOStom — http:www.soundonsound.com/sos/Mar02/articles/synthsecrets0302.asp
// Modified by Bruno Ruviaro and Josh Mitchell 8/19.
// Adapted to SuperDirt by Aleksandr Yakunichev, hi@ya.codes
//
// voice - controls modulation input phase in radians (min: 0, max: your sanity)
SynthDef(\sostoms, {
  arg out, pan, sustain = 0.5, freq = 261.626, voice = 0.5;
  var envelope, source;

  source = PMOsc.ar(Saw.ar(freq * 0.9), freq * 0.85, voice, mul: 6.dbamp);
  source = source + SinOsc.ar([freq, freq * 0.8]);
  source = Mix.ar(source);
  source = LeakDC.ar(source + Crackle.ar(2)) * (-3).dbamp;

  envelope = Env.perc(0.005, sustain, (-4).dbamp, -6).ar(Done.freeSelf);

  Out.ar(out, DirtPan.ar(source, ~dirt.numChannels, pan, envelope));
},
metadata: (
  credit: "Renick Bell",
  category: \drums,
  tags: [\pitched, \tom, \sos]
)).add;
);

(
// Retrieved from http:sccode.org/1-5aD
// DrumSynths SC Example — SOS Drums by Renick Bell, renick_at_gmail.com
// recipes from Gordon Reid in his Sound on Sound articles
// SOSsnare — http:www.soundonsound.com/sos/Mar02/articles/synthsecrets0302.asp
// Latch.ar(WhiteNoise.ar(0.1), Impulse.ar(nyquist * 2)) is added aliasing for effect
// Modified by Bruno Ruviaro and Josh Mitchell 8/19.
// Adapted to SuperDirt by Aleksandr Yakunichev, hi@ya.codes
//
// voice - controls modulation input phase in radians (min: 0, max: your sanity)
// semitone - modulation frequency in semitones of fundamental
// pitch1 - resonance filter frequency (Hz)
// resonance - resonance of bandpass and resonz filters (min: 0, max: 1)
SynthDef(\sossnare, {
  arg out, pan, freq = 405, voice = 0.385, semitone = 0.452, pitch1 = 2000, resonance = 0.1, sustain = 0.5;
  var source, noise, envelope;

  source = PMOsc.ar(Saw.ar(freq * 0.85), freq * semitone, voice);

  noise = Latch.ar(WhiteNoise.ar(0.1), Impulse.ar(1700 * 2));
  noise = BRF.ar(noise, 4 * pitch1, resonance, 0.5);
  noise = BRF.ar(noise, 2.5 * pitch1, resonance, 0.5);
  noise = BRF.ar(noise, 1.8 * pitch1, resonance, 0.5);
  noise = BRF.ar(noise, pitch1, resonance, Env.perc(0.005, sustain, -4).ar);
  noise = Resonz.ar(noise, pitch1, 1, 40);

  envelope = Env.perc(0.005, sustain, 0.5, -4).ar(Done.freeSelf);

  Out.ar(out, DirtPan.ar((source + noise) * 4.dbamp, ~dirt.numChannels, pan, envelope));
},
metadata: (
  credit: "Renick Bell",
  category: \drums,
  tags: [\pitched, \snare, \sos]
)).add;
);
