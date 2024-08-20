
(
	SynthDef(\sawtooth, {|out, rate=1, decay=0, sustain=1, pan, accelerate, freq = 	130.8, speed=1|
		// var env = EnvGen.ar(Env.pairs([[0,0],[0.05,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -3), timeScale:sustain, doneAction:2);
        // // EnvGen.ar(Env.adsr())

        // EnvGen.kr(Env(

        // ))
		var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
	

		// var sound = MoogFF.ar(
		// 	(0.5 * Mix.arFill(3, {|i|  SawDPW.ar(basefreq * ((i-1)*voice/50+1), 0)})) + (0.5 * LFTri.ar(basefreq2, voice)),
		// 	LFTri.ar(basefreq/64*rate, 0.5).range(lfof1,lfof2),
		// 	resonance*4);
		// sound = sound.tanh*2;
        var sound = Saw.ar(basefreq, 1.0);
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan));
	}).add
);