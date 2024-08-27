

(
   {
    var unison = ~unison.value;

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

        SynthDef(\supersaw, {|out, rate=1, decay=0, sustain=1, pan, accelerate, freq =130.8, speed=1, spread = 0.5, detune = 0.15|
            var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
            var sound;
            var voices = 7;
            var panspread = spread;
            var freqspread = detune;
            var gain1 = sqrt(1 - panspread);
            var gain2 = sqrt(panspread);     
            voices = clip(voices, 0, 100);

            if (voices < 1) {
                panspread = 0;
            };

            sound = Splay.arFill(voices, {|i| 
                SawDPW.ar(basefreq * pow(2, StrudelUtils.getUnisonDetune(voices, freqspread, i) / 12),
                    iphase:  TRand.kr(-1, 1, Impulse.kr(0))
                )
            },spread: panspread, level: 1, center: 0);

            Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan));
        }).add;
    
    }.value

    
);
