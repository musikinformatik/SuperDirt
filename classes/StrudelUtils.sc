
StrudelUtils {
    *lerp {|a, b, n|
        var result = n * (b - a) + a;
        ^result;
    }
	*getUnisonDetune { | unison, detune, voiceIndex |
        var amount = StrudelUtils.lerp(detune * -0.5, detune * 0.5, voiceIndex / (unison - 1));
		^amount;
	}
	
}