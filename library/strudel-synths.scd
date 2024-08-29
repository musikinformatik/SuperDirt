(
        var sawfunc, supersawfunc;

        supersawfunc = {|voices|
            {|out = 0, rate=1, decay=0, sustain=1, pan= 0, accelerate=0, freq =130.8, speed=1, spread = 0.5, detune = 0.15|
                var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
                var sound;
                var panspread = spread;
                var freqspread = detune;

                if (voices < 2) {
                    panspread = 0;
                };

                sound = Splay.arFill(voices, {|i|
                    SawDPW.ar(basefreq * pow(2, StrudelUtils.getUnisonDetune(voices, freqspread, i) / 12),
                        iphase:  TRand.kr(-1, 1, Impulse.kr(0))
                    )
                },spread: panspread, level: 1, center: 0);

                Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan));
            }
        };

        (2..10).do{|voices|
            var name = "supersaw" ++ voices;
            SynthDef.new(name, supersawfunc.value(voices)).add;
        };

        ~dirt.soundLibrary.addSynth(\supersaw,
            (playInside: { |e|
                (
                    instrument: "supersaw" ++ clip(~unison.value, 1, 10),
                    out: ~out,
                    freq: ~freq,
                    amp: ~amp,
                    detune: ~detune,
                    spread: ~spread,
                    group: ~synthGroup
                ).play
            })
        );

        sawfunc = {
           {|out, rate=1, decay=0, sustain=1, pan, accelerate, freq = 	130.8, speed=1|
            var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
            var sound = SawDPW.ar(freq: basefreq);
            Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan));
          }
        };

        SynthDef.new(\supersaw1, sawfunc.value()).add;
        SynthDef(\sawtooth, sawfunc.value()).add;

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

)

