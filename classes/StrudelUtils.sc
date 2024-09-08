
StrudelUtils {
    *lerp {|a, b, n|
        var result = n * (b - a) + a;
        ^result;
    }
	*getUnisonDetune { | unison, detune, voiceIndex |
        var amount = StrudelUtils.lerp(detune * -0.5, detune * 0.5, voiceIndex / (unison - 1));
		^amount;
	}
    *calculateCutoff {|cutoff=440, anchor=0, envamt=0, hold=0, holdtime, attack, decay, release, cutmin=20, cutmax=20000|
		var offset = envamt.abs * anchor;

		var envmin = clip(2 ** (offset * -1) * cutoff, cutmin, cutmax); 
		var envmax = clip(2 ** (envamt.abs - offset) * cutoff, cutmin, cutmax);
      
		cutoff = EnvGen.ar(
		   Env.adsr(
			attackTime: attack, 
			decayTime: decay, 
			releaseTime: release, 
			sustainLevel: hold,
			peakLevel:  envmax - envmin, 
			bias: envmin,
			curve: -4
		   ),
		   gate: Trig.ar(1, holdtime)
	    );
        ^cutoff;
    }
    *baseNote {
        ^36;
    }
    //makeup gain for sample buffer
    *sampleGain {
        ^1.7;
    }
	*gainCurve {|gain=1|
		// ^gain
	  ^pow(gain, 2)
	}
    
}

