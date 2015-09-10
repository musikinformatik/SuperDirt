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
			start: ~start,
			pan: ~pan,
			out: ~out
		]);
}, { ~buffer.notNil });

/* 
this is a generic synth, which allows us to embed a SynthDef name in a tidal pattern next to sample names

it could receive any number of the parameters in the event, e.g.
sustain, speed, endSpeed, start, end, pan, accelerate, offset, cps

it ought to use: out
*/

~dirt.addModule('synth', { |dirtEvent| dirtEvent.sendSynth(~instrument) }, { ~buffer.isNil });

/*
these function as effects on the input of the synth or sample (see SynthDefs in core-synths)
they respond to the existence of a value for one of the tidal parameters
*/

~dirt.addModule('vowel',
	{ |dirtEvent|
		var vowel = ~dirt.vowels[~vowel];
		if(vowel.notNil) {
			dirtEvent.sendSynth("dirt_vowel" ++ ~numChannels,
				[
					out: ~out,
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
		dirtEvent.sendSynth("dirt_shape" ++ ~numChannels,
			[
				shape: ~shape,
				out: ~out
		])

}, { ~shape.notNil and: { ~shape != 0 } });

~dirt.addModule('hpf',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_hpf" ++ ~numChannels,
			[
				hcutoff: ~hcutoff,
				hresonance: ~hresonance,
				out: ~out
		])

}, { ~hcutoff.notNil and: { ~hcutoff != 0 } });

~dirt.addModule('bpf',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_bpf" ++ ~numChannels,
			[
				bandqf: ~bandqf,
				bandq: ~bandq,
				out: ~out
		])

}, { ~bandqf.notNil and: { ~bandqf != 0 } });

~dirt.addModule('crush',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_crush" ++ ~numChannels,
			[
				crush: ~crush,
				out: ~out
		])

}, { ~crush.notNil and: { ~crush != 0 } });


~dirt.addModule('coarse',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_coarse" ++ ~numChannels,
			[
				coarse: ~coarse,
				out: ~out
		])

}, { ~coarse.notNil and: { ~coarse > 1 } }); // coarse == 1 => full rate



);
