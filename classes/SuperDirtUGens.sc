
/*

A few UGen classes that build subgraphs for SuperDirt Synths

The panners take care of different combinations of in and out channels.

They should be used through the

*defaultPanningFunction*

which can be modified before starting a SuperDirt instance. This is still a bit experimental, but should work on any number of input and output channel settings.

Generally, these pseudo ugens below expect a bipolar pan range [-1..1]
DirtEvent converts the tidal input: ~pan = ~pan * 2 - 1;

Where we write -1 for pan in tidal, we get -3, which should be equivalent to 1.
In multichannel panning this is not an issue, because it is cyclic in the range [-1..1], or [0..2]
In stereo panning, we need to .fold(-1, 1)

*/


DirtPan {
	classvar <>defaultPanningFunction;

	*initClass {
		// signals is an array of arbitrary size
		defaultPanningFunction = #{ | signals, numChannels, pan, mul |
			var channels, inNumChannels;
			if(numChannels > 2) {
				DirtSplayAz.ar(
					numChannels,
					signals,
					\span.ir(1),
					pan,
					mul,
					\splay.ir(1),
					\panwidth.ir(2),
					\orientation.ir(0)
				)
			} {
				//DirtSplay2.ar(signals, \span.ir(1), pan, mul)
				DirtPanBalance2.ar(signals, \span.ir(1), pan, mul)
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



DirtPanBalance2 : UGen {

	*ar { | signals, span = 1, pan = 0.0, mul = 1 |
		var n, pos, amp;
		signals = signals.asArray;
		n = signals.size;
		if(n == 0) { Error("DirtSplay input has not even one channel. Can't pan no channel, sorry.").throw };
		if(n == 1) {
			^Pan2.ar(signals[0], pan.fold(-1, 1), mul)
		} {
			if(n > 2) { signals = Splay.ar(signals, span) };
			^Balance2.ar(signals[0], signals[1], pan.fold(-1, 1), mul)
		}
	}
}


DirtSplay2 : UGen {

	*ar { | signals, span = 1, pan = 0.0, mul = 1 |
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

	// pan: circular pan argument from -1 .. 1, where -1 is the first channel, 0 the center, and 1 is also the first channel
	// span: how much the channels are distributed over the whole of numChannels. 0 means mixdown
	// splay: rescaling of span relative to the number of output channels

	// For splay = 1, and span = 1, the N synth channels should cover the whole output channel field.
	// For splay = 0, and span = 1, the N synth channels should cover only adjacent channels up to N of the output channels.
	// Intermediate values of splay give intermediate ranges.

	*ar { | numChannels, signals, span = 1, pan = 0.0, mul = 1, splay = 1, width = 2, orientation = 0 |
		var channels, n;
		signals = signals.asArray;
		n = signals.size;
		if(n == 0) { Error("DirtSplay input has not even one channel. Can't pan no channel, sorry.").throw };
		span = span * splay.linlin(0, 1, numChannels / n, 1);
		pan = pan + 1; // for PanAz, the first/last channel is not 0, but 1.
		channels = signals.collect { |x, i|
			var panOffset = i / (numChannels) * 2 * span;
			PanAz.ar(numChannels, x, panOffset + pan, width: width, orientation: orientation)
		};

		^Mix(channels)

	}
}


DirtEnvGen : UGen {
	*ar { |env, begin, end, speed, sustain, endSpeed|
		var stretch = env.times.sum * if(endSpeed.isNil) { speed } { speed + endSpeed * 0.5 };
		var phase = DirtPhase.ar(begin, end, speed, sustain, endSpeed) * stretch;
		^IEnvGen.ar(env, phase)
	}
}

DirtPhase : UGen {
	*ar { |begin = 0, end = 1, speed = 1, sustain = 1, endSpeed|
		var rate = DirtRateScale.ar(speed, sustain, endSpeed ? speed);
		^LFSaw.ar(rate.reciprocal, 1, speed.sign).range(begin, end)
	}
}

DirtRateScale : UGen {
	*ar { |speed = 1, sustain = 1, endSpeed|
		^Line.ar(speed, endSpeed ? speed, sustain)
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
		// immediately pause when started
		PauseSelf.kr(Impulse.kr(0));
		// when resumed and no sound is coming in, wait a while before ending again
		signal = signal.abs + Trig1.ar(\resumed.tr(0), graceTime);
		DetectSilence.ar(signal, time:graceTime, doneAction:1);
	}

}


