/*

CORE MODULES
(REQUiRE: CORE SYNTHS)

Core Modules: these are called for each event from tidal,
and they represent the list of possible (effect) synths on the event level

Usually, they correspond to a SynthDef (here in core-synths), you could call any function in them
They will be called when the test is fulfilled (e.g. ~vowel.notNil)

You can't currently add your own, because Tidal needs to support this extension first.

*/

(

// argumets could be omitted using getMsgFunc, but for making it easier to understand, we write them out

~dirt.addModule('sound',
	{ |dirtEvent|
		dirtEvent.sendSynth(~instrument,  [
			bufnum: ~buffer,
			sustain: ~sustain,
			speed: ~speed,
			endSpeed: ~endSpeed,
			startFrame: ~startFrame,
			endFrame: ~endFrame,
			pan: ~pan,
			out: ~synthBus
		]);
}, { ~buffer.notNil });

// this is a generic synth, which could receive any number of the parameters below
~dirt.addModule('synth',
	{ |dirtEvent|
		dirtEvent.sendSynth(~instrument,  [
			sustain: ~sustain,
			speed: ~speed,
			endSpeed: ~endSpeed,
			start: ~start,
			end: ~end,
			pan: ~pan,
			accelerate: ~accelerate,
			offset: ~offset,
			cps: ~cps,
			out: ~synthBus
		]);
}, { ~buffer.isNil });

~dirt.addModule('vowel',
	{ |dirtEvent|
		var vowel = ~dirt.vowels[~vowel];
		if(vowel.notNil) {
			dirtEvent.sendSynth("dirt_vowel" ++ ~numChannels,
				[
					out: ~synthBus,
					vowelFreqs: vowel.freqs,
					vowelAmps: vowel.amps,
					vowelRqs: vowel.rqs,
					resonance: ~resonance,
				]
			)
		}

}, { ~vowel.notNil });


~dirt.addModule('shape',
	{ |dirtEvent|
		var shape = (2.0 * ~shape) / (1.0 - ~shape);
		dirtEvent.sendSynth("dirt_shape" ++ ~numChannels,
			[
				shape: shape,
				out: ~synthBus
		])

}, { ~shape.notNil and: { ~shape != 0 } });

~dirt.addModule('hpf',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_hpf" ++ ~numChannels,
			[
				hcutoff: ~hcutoff,
				hresonance: ~hresonance,
				out: ~synthBus
		])

}, { ~hcutoff.notNil and: { ~hcutoff != 0 } });

~dirt.addModule('bpf',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_bpf" ++ ~numChannels,
			[
				bandqf: ~bandqf,
				bandq: ~bandq,
				out: ~synthBus
		])

}, { ~bandqf.notNil and: { ~bandqf != 0 } });

~dirt.addModule('crush',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_crush" ++ ~numChannels,
			[
				crush: ~crush,
				out: ~synthBus
		])

}, { ~crush.notNil and: { ~crush != 0 } });


~dirt.addModule('coarse',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_coarse" ++ ~numChannels,
			[
				coarse: ~coarse,
				out: ~synthBus
		])

}, { ~coarse.notNil and: { ~coarse > 1 } }); // coarse == 1 => full rate



);