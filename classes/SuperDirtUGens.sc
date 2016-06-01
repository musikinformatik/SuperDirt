
/*

A few UGen classes that build subgraphs for SuperDirt Synths

*/



/*
convenience methods for panning and releasing
*/

DirtPan {
	classvar <>defaultMixingFunction;

	*initClass {

		// the channels are passed in as N x M array
		// where N = number of input channels
		// M = number of output channels to pan across

		 // mono mixdown
		defaultMixingFunction = #{ |channels|
			channels.sum
		};

		/*
		a variant:

		// wrapped mutual crossfade
		defaultMixingFunction = #{ |channels|
			channels.flop.collect { |ch, i| ch[i] ?? { DC.ar(0) } }
		};




		you can set them via DirtPan.defaultMixingFunction = { ... your function ... }
		and/or pass in a synth specific mixingFunction in the SynthDef
		*/
	}

	*ar { |signal, numChannels, pan = 0.0, mul = 1.0, mixingFunction|

		var output;

		pan = pan * 2 - 1; // convert unipolar (0..1) range into bipolar compatible one
		signal = signal.asArray; // always keep the same shape


		if(numChannels == 2) {
			output = Pan2.ar(signal, pan, mul)
		} {
			output = PanAz.ar(numChannels, signal, pos: pan, level: mul, orientation: 0)
		};
		^value(mixingFunction ? defaultMixingFunction, output)

	}
}


/*
In order to avoid bookkeeping on the language side, we implement cutgroups as follows:
The language initialises the synth with its sample id (some number that correlates with the sample name) and the cutgroup.
Before we start the new synth, we send a /set message to all synths, and those that match the specifics will be released.
*/

DirtGateCutGroup {

	*ar { |releaseTime = 0.02, doneAction = 2|
		// this is necessary because the message "==" tests for objects, not for signals
		var same = { |a, b| BinaryOpUGen('==', a, b) };
		var sameCutGroup = same.(\cutGroup.ir(0), abs(\gateCutGroup.kr(0)));
		var sameSample = same.(\sample.ir(0), \gateSample.kr(0));
		var which = \gateCutGroup.kr(0).sign; // -1, 0, 1
		var free = Select.kr(which + 1, // 0, 1, 2
			[
				sameSample,
				0.0, // default cut group 0 doesn't ever cut
				1.0
			]
		) * sameCutGroup; // same cut group is mandatory

		^EnvGen.kr(Env.cutoff(releaseTime), (1 - free), doneAction:doneAction);

	}
}




