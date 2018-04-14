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
(
SynthDef(\imp, { |out, sustain = 1, freq = 440, speed = 1, begin=0, end=1, pan, accelerate, offset|
	var env, sound, rate, phase;
	env = EnvGen.ar(Env.perc(0.01, 0.99, 1, -1), timeScale:sustain, doneAction:2);
	phase = Line.kr(begin, end, sustain);
	rate = (begin + 1) * (speed + Sweep.kr(1, accelerate));
	sound = Blip.ar(rate.linexp(0, 1, 1, freq) * [1, 1.25, 1.51, 1.42], ExpRand(80, 118) * phase).sum;
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add
);


// modulated phase mod sines
(
SynthDef(\psin, { |out, sustain = 1, freq = 440, speed = 1, begin=0, end=1, pan, accelerate, offset, modfreq = 40|
	var env, sound, rate, phase, amp;
	amp = AmpCompA.kr(freq);
	env = EnvGen.ar(Env.perc(0.002, sustain, 1, -1), doneAction:2);
	phase = Line.ar(begin, end, sustain);
	rate = speed + Sweep.kr(1, accelerate);
	sound = SinOsc.ar(freq, SinOsc.ar(modfreq * (1..5), 0, 1 - phase * 10 * env / (1..5), 0.5pi)).sum;
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add
);

// cursor modulated phase mod sines
(
SynthDef(\pmsin, { |out, sustain = 1, freq = 440, speed = 1, begin=0, end=1, pan, accelerate, offset|
	var env, sound, rate, phase, modfreq, amp;
	freq = (MouseX.kr(30, 80).round + freq);
	modfreq = MouseY.kr(1, 200, 1);
	amp = AmpCompA.kr(freq);
	env = EnvGen.ar(Env.perc(0.002, sustain, 1, -1), doneAction:2);
	phase = Line.ar(begin, end, sustain);
	rate = speed + Sweep.kr(1, accelerate);
	sound = SinOsc.ar(freq, SinOsc.ar(modfreq * (1..5), 0, 1 - phase * 10 * env / (1..5), 0.5pi)).sum;
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add
);

// live audio input
(
SynthDef(\in, { |out, sustain = 1, speed = 1, begin = 0, end = 1, pan, accelerate, offset|
	var env, sound, rate, phase;
	phase = Line.ar(begin, end, sustain);
	rate = (begin + 1) * (speed + Sweep.kr(1, accelerate));
	sound = SoundIn.ar([0, 1]); // stereo in
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan)
	)
}).add
);

// pitch shifted live audio input
(
SynthDef(\inr, { |out, sustain = 1, freq = 440, speed = 1, begin=0, end=1, pan, accelerate, offset|
	var env, sound, rate, phase;
	phase = Line.ar(begin, end, sustain);
	rate = (begin + 1) * (speed + Sweep.kr(1, accelerate)) * freq / 440;
	sound = SoundIn.ar([0, 1]); // stereo in
	sound = PitchShift.ar(sound, 0.1, rate, 0.02, 0.01);
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan)
	)
}).add
);

// gabor grain
(
SynthDef(\gabor, { |out, sustain = 0.03, freq = 440, pan = 0, width = 0.3|
	var env, sound;
	sound = SinOsc.ar(freq, 0.5pi);
	env = LFGauss.ar(sustain, width, loop: 0).range(0, 1);
	OffsetOut.ar(out,
		DirtPan.ar(env * sound, ~dirt.numChannels, pan)
	)
}).add;
);

// dirac delta function approximation
(
SynthDef(\dirac, { |out, sustain = 0.03, pan = 0|
	OffsetOut.ar(out,
		DirtPan.ar(Impulse.ar(0), ~dirt.numChannels, pan)
	)
}).add;
);

// shepard on a cycle
(
SynthDef(\cyclo, { |out, freq, sustain = 1, speed = 1, begin = 0, end = 1, pan, accelerate, cycle, ratio = 1|
	var env, sound, rate, phase;

	env = EnvGen.ar(Env.perc(0.01, 0.99, 1, -1), timeScale:sustain, doneAction:2);
	phase = Line.kr(begin, 1 - end, sustain);
	rate = (begin + 1) * (speed + Sweep.kr(1, accelerate));

	freq = (cycle * speed) % ((1..16) * ratio + phase) + 1 * freq * rate;

	sound = SinOsc.ar(freq).mean;
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add
);

// Phase Modulation Synth
// 
// Parameters:
// pitch2: carrierfrequency (works just like speed, eg # pitch "2.0 3.0 4.0")
// detune: controls the modulation index (put value patterns between 0.0 and
// 1.0)
(
SynthDef(\pm, {
    |out, 
    sustain = 1, 
    freq = 440, 
    speed = 1, 
    detune = 0.25,
    pitch2 = 3, 
    begin=0, end=1, pan, accelerate, amp = 1, offset|
	var env, sound, rate, phase;
	env = EnvGen.ar(Env.perc(0.01, 0.99, amp * 0.1, -1), timeScale:sustain, doneAction:2);
	phase = Line.kr(begin, end, sustain);
	sound = PMOsc.ar(freq * (speed + Sweep.kr(1, accelerate)), // carrier freq 
            freq * (pitch2 + Sweep.kr(1, accelerate)), // modulation freq 
            detune, // Phase Modulation Index 
            phase);
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
    )
}).add;
);

// FM Granular 
// 
// Parameters:
// pitch2: carrierfrequency (works just like speed, eg # pitch "2.0 3.0 4.0")
// detune: controls the modulation index (put value patterns between 0.0 and
// 1.0)
(
SynthDef(\fmgrain, {
    |out, 
    graindur=0.1,
    sustain = 1, 
    freq = 440, 
    speed = 1, 
    triggerrate = 10,
    gate = 1,
    detune = 0.75,
    pitch2 = 0.25, 
    begin=0, end=1, pan, accelerate, amp = 1|
	var env, sound, rate, phase;
	env = EnvGen.ar(Env.perc(0.01, 0.99, amp * 0.1, -1), timeScale:sustain, doneAction:2);
    sound = FMGrain.ar(trigger: Impulse.ar(triggerrate*speed,0, gate), 
                        dur: graindur/speed, // the higher the speed, the smaller the grain
                        carfreq: freq * (speed + Sweep.kr(1, accelerate)),
                        modfreq: freq * (pitch2 + Sweep.kr(1, accelerate)),
                        index: detune);
	OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
    )
}).add;
);

// WhistleSynth 
// 
// Whistle into your computer
// and control a fat, three oscillator bass synth.
// It extracts pitch information from your voice
// but you can still use the speed parameter to scale.
(
SynthDef(\whistle, {
    |out, 
    inputchannel = 0, // Built in mic or the first input on your computer
    graindur=0.1,
    sustain = 1, 
    freq = 440, 
    speed = 1, 
    gate = 1,
    cutoff = 2000,
    detune = 0.75,
    begin=0, end=1, pan, accelerate, amp = 1|
	var env, sound, sound2, sound3, rate, phase, extractedpitch, hasFreq;
	env = EnvGen.ar(Env.perc(0.01, 0.99, amp * 0.1, -1), timeScale:sustain, doneAction:2);

    // Extract pitch information from audio input
    sound = SoundIn.ar([inputchannel]); 
    #extractedpitch, hasFreq = Pitch.kr(sound); // Pitch follower 
    extractedpitch = extractedpitch * (speed + Sweep.kr(1, accelerate));
    
    // Layer three oscillators and slightly detune them to get a nice, fat sound
    sound = LFTri.ar(extractedpitch/4, 1, 
            mul:Lag.kr(hasFreq)*gate);

    sound2 = LFSaw.ar((extractedpitch/8) * (1+detune), 1, 
            mul:Lag.kr(hasFreq)*gate) * detune;

    sound3 = LFPar.ar((extractedpitch/16) * (1.05+detune), 1, 
            mul:Lag.kr(hasFreq)*gate) * detune;
    
    sound = Splay.ar([sound, sound2, sound3]);        
    sound = LPF.ar(sound, Lag.kr(hasFreq.range(120,cutoff)));

    OffsetOut.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
    )
}).add;
);

)
