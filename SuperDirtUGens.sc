
/*

A few UGen classes that build subgraphs for SuperDirt Synths

*/



/*
convenience methods for panning and releasing
*/

DirtPan {

	*ar { |signal, numChannels, pan = 0.0, mul = 1.0, mix = false|

		var output, mono;

		mono = signal.size <= 1;

		if(numChannels == 2) {
			output = Pan2.ar(signal, (pan * 2) - 1, mul)
		} {
			output = PanAz.ar(numChannels, signal, pan, mul)
		};

		if(mono.not) {
			if(mix.not) {
				// if multichannel, take only the diagonal
				output = numChannels.collect(output[_]);
			};
			output = output.sum;
		};

		^output

	}
}


/*
In order to avoid bookkeeping on the language side, we implement cutgroups as follows:
The language initialises the synth with its sample id (some number that correlates with the sample name) and the cutgroup.
Before we start the new synth, we send a /set message to all synths, and those that match the specifics will be released.
*/

DirtGateCutGroup {

	*ar { |sustain = 1, releaseTime = 0.02, doneAction = 2|
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

		^EnvGen.ar(Env([1, 1, 0], [sustain, releaseTime]), doneAction:doneAction)
		*
		EnvGen.kr(Env.cutoff(releaseTime), (1 - free), doneAction:doneAction);

	}
}

//
// DirtReleaseAfter {
//
// 	*ar { |sustain, releaseTime = 0.02, doneAction = 2|
// 		^DirtGateCutGroup.ar(sustain, releaseTime, doneAction)
// 	}
// }




