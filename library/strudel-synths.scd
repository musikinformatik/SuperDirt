(
        var sawfunc, supersawfunc;
        var numChannels = ~dirt.numChannels;
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
                    instrument: "supersaw" ++ clip(~unison.value ? 5, 1, 10),
                    out: ~out,
                    freq: ~freq,
                    speed: ~speed,
                    accelerate: ~accelerate,
                    amp: ~amp,
                    detune: ~detune.value ? ~n.value ? 0.18,
                    spread: ~spread ? 0.6,
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


    //EFFECTS

    SynthDef("gain" ++ numChannels, { |out, gain=1.0 |
		var signal = In.ar(out, numChannels) * gain;
		ReplaceOut.ar(out, signal)
	}, [\ir, \kr, \kr]).add;

    ~dirt.addModule('postgain',
        { |dirtEvent|
            dirtEvent.sendSynth("gain" ++ ~numChannels,
                [
                    gain: ~postgain,
                    out: ~out
            ])

    }, { ~postgain.notNil });

    SynthDef("strudel_lpf" ++ numChannels, { |out, cutoff = 440, resonance = 0, attack, hold, decay, envamt = 0, anchor = 0, release, holdtime |
		var signal = In.ar(out, numChannels);
		cutoff = StrudelUtils.calculateCutoff(cutoff,anchor, envamt, hold, holdtime, attack, decay, release, cutmax: SampleRate.ir / 2);
        resonance = StrudelUtils.calculateResonance(resonance);
		signal = IIRFilter.ar(signal, cutoff, resonance);
		ReplaceOut.ar(out, signal)
	}, [\ir, \kr, \kr]).add;

    ~dirt.addModule('lpf',
        { |dirtEvent|
            dirtEvent.sendSynth("strudel_lpf" ++ ~numChannels,
                [
                    cutoff: ~cutoff,
                    resonance: ~resonance,
                    envamt: ~lpenv,
                    attack: {~lpattack.value ? ~attack.value},
                    decay: {~lpdecay.value ? ~decay.value},
                    hold: { ~lpsustain.value ? ~hold.value ? ~lpdecay.isNil},
                    release: {~lprelease.value ? ~release.value},
                    holdtime: ~sustain,
                    out: ~out
            ])

    }, { ~cutoff.notNil });


    SynthDef("strudel_distort" ++ numChannels, { |out, shape = 0, postgain = 1|
		
        var signal = In.ar(out, numChannels), amp = 1;
        
		shape = exp(shape) - 1;
        // shape = min(shape, 1.0 - 4e-10); // avoid division by zero
        postgain = clip(postgain, 0.001, 1);

		signal = ((1 + shape) * signal / (1 + (shape * abs(signal)))) * postgain;
		ReplaceOut.ar(out, signal * amp)
	}, [\ir, \kr]).add;

    ~dirt.addModule('distort',
	{ |dirtEvent|
		dirtEvent.sendSynth('strudel_distort' ++ ~numChannels,
			[
				shape: ~distort,
                postgain: ~distortvol ? 1,
				out: ~out
		])
    }, { ~distort.notNil });

	SynthDef("strudel_envelope" ++ numChannels, { |out, attack, decay, hold, holdtime = 0, release, curve | 
		var signal = In.ar(out, numChannels);
        var volenv = EnvGen.ar(
		   Env.adsr(
			attackTime: attack, 
			decayTime: decay, 
			releaseTime: release, 
			sustainLevel: hold,
			peakLevel:  1, 
			curve: curve
		   ),
		   gate: Trig.ar(1, holdtime)
	    );
		signal = signal * volenv;
		ReplaceOut.ar(out, signal);
	}, [\ir, \ir, \ir, \ir, \ir]).add;

    ~dirt.addModule('envelope',
	{ |dirtEvent|
		dirtEvent.sendSynth('strudel_envelope' ++ ~numChannels,
			[
				attack: ~attack,
				decay: ~decay,
				hold: { ~hold.value ? ~decay.isNil },
				holdtime: ~sustain,
				release: ~release,
				curve: {~curve.value ? -2},
				out: ~out
		])
    }, { ~attack.notNil or: { ~release.notNil } or: { ~decay.notNil } or: { ~hold.notNil }});

   ~dirt.orderModules(['sound','supersaw','dirt_gate','lpf','bpf','hpf','phaser','shape','crush','coarse','envelope','postgain']);

)

