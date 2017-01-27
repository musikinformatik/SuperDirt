
/*

A few UGen classes that build subgraphs for SuperDirt Synths

The panners take care of different combinations of in and out channels.

They should be used through the

*defaultPanningFunction*

which can be modified before starting a SuperDirt instance. This is still a bit experimental, but should work on any number of input and output channel settings.

*/

DirtPan {
	classvar <>defaultPanningFunction;

	*initClass {
		// signals is an array of arbitrary size
		defaultPanningFunction = #{ | signals, numChannels, pan, mul |
			var channels, inNumChannels;
			var spread, withd, splay, orientation;
			if(numChannels > 2) {
				DirtSplayAz.ar(numChannels, signals, \spread.ir(1), pan, mul,
					\splay.ir(1), \panwidth.ir(2), \orientation.ir(0.5))
			} {
				//DirtSplay2.ar(signals, \spread.ir(1), pan, mul)
				DirtPanFixed2.ar(signals, \spread.ir(1), pan, mul)
			}
		}
	}

	*ar { |signal, numChannels, pan = 0.0, mul = 1.0, panningFunction|
		^value(panningFunction ? defaultPanningFunction, signal.asArray, numChannels ? 2, pan ? 0, mul ? 1.0)
	}

	*defaultMixingFunction_ {
		"DirtPan can be completely configured, so please just make your own defaultPanningFunction".postln;
		^this.deprecated(thisMethod)
	}
}



DirtPanFixed2 : UGen {

	*ar { | signals, spread = 1, pan = 0.0, mul = 1 |
		var n, pos, amp;
		signals = signals.asArray;
		n = signals.size;
		if(n == 0) { Error("DirtSplay input has not even one channel. Can't pan no channel, sorry.").throw };
		if(n == 1) {
			^Pan2.ar(signals[0], pan, mul)
		} {
			if(n > 2) { signals = Splay.ar(signals, spread) };
			^signals * [1 - pan, 1 + pan].clip2
		}
	}
}


DirtSplay2 : UGen {

	*ar { | signals, spread = 1, pan = 0.0, mul = 1 |
		var n, pos, pan1;
		signals = signals.asArray;
		n = signals.size;
		if(n == 0) { Error("DirtSplay input has not even one channel. Can't pan no channel, sorry.").throw };
		if(n == 1) {
			^Pan2.ar(signals[0], pan, mul)
		} {
			pan1 = pan * 2 - 1;
			^signals.sum { |x, i|
				var pos = ((i / (n - 1)) + pan1).fold(-1, 1);
				Pan2.ar(x, pos, mul)
			}
		}
	}

}

DirtSplayAz : UGen {

	*ar { | numChannels, signals, spread = 1, pan = 0.0, mul = 1, splay = 1, width = 2, orientation = 0.5 |
		var n, pos, channels;
		n = signals.size;
		if(n == 0) { Error("DirtSplay input has not even one channel. Can't pan no channel, sorry.").throw };
		spread = spread * splay.linlin(0, 1, n / numChannels, 1);
		pos = if(n == 1) { pan } { [ pan - spread, pan + spread ].resamp1(n) };
		channels = PanAz.ar(numChannels, signals, pos: pos, level: mul, width: width, orientation: orientation);
		^channels.flop.collect(Mix(_))
	}

}


/*
In order to avoid bookkeeping on the language side, we implement cutgroups as follows:
The language initialises the synth with its sample id (some number that correlates with the sample name) and the cutgroup.
Before we start the new synth, we send a /set message to all synths, and those that match the specifics will be released.
*/

DirtGateCutGroup {

	*ar { | releaseTime = 0.02, doneAction = 2 |
		// this is necessary because the message "==" tests for objects, not for signals
		var same = { |a, b| BinaryOpUGen('==', a, b) };
		var or = { |a, b| (a + b) > 0 };
		var sameSample = same.(\sample.ir(0), \gateSample.kr(0));
		var free = or.(\cutAll.kr(0), sameSample);
		^EnvGen.kr(Env.cutoff(releaseTime), (1 - free), doneAction:doneAction);
	}
}


DirtPause {

	*ar { | signal, graceTime = 1 |
		PauseSelf.kr(Impulse.kr(0));
		DetectSilence.ar(signal, time:graceTime, doneAction:1);
	}

}


