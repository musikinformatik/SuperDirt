

(
   
	SynthDef(\sawtooth, {|out, rate=1, decay=0, sustain=1, pan, accelerate, freq = 	130.8, speed=1|
		var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
        var sound = SawDPW.ar(freq: basefreq);
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan));
	}).add;

   SynthDef(\sine, {|out, rate=1, decay=0, sustain=1, pan, accelerate, freq=130.8, speed=1|
		var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
        var sound = SinOsc.ar(basefreq);
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan));
	}).add;

    SynthDef(\triangle, {|out, rate=1, decay=0, sustain=1, pan, accelerate, freq = 	130.8, speed=1|
		var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
        var sound = LFTri.ar(basefreq);
		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan));
	}).add;

    SynthDef(\supersaw, {|out, rate=1, decay=0, sustain=1, pan, accelerate, freq =130.8, speed=1, unison = 5, spread = 0.5, detune = 0.15|
		var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
        var sound;
        var voicedetuneamt;
        var voices = unison;
        var panspread = spread;
        var freqspread = detune;
        var gain1 = sqrt(1 - panspread);
        var gain2 = sqrt(panspread);
        
        voices = clip(unison, 0, 100);
        panspread = if (voices > 1) { clip(spread,0,1) } {0};

        panspread = panspread * 0.5 + 0.5;
        sound = Mix.arFill(voices, {|n| 
        voicedetuneamt =  squared(StrudelUtils.getUnisonDetune(voices, freqspread, n) / 12);
       


        SawDPW.ar(basefreq *  voicedetuneamt)
        });




		Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan));
	}).add;

    
);
