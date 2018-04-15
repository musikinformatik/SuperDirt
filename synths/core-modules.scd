/*

CORE MODULES
(REQUiRE: CORE SYNTHS)

Core Modules: these are called for each event from tidal,
and they represent the list of possible (effect) synths on the event level

Usually, they correspond to a SynthDef (here in core-synths), you could call any function in them
They will be called when the test is fulfilled (e.g. ~vowel.notNil)

You can't currently add your own, because Tidal needs to support this extension first.

*/



/*
The sound source to be filtered by later stages (modules)

This could be:

- a sample that is played
- a generic synth, which allows us to embed a SynthDef name in a tidal pattern next to sample names

A SynthDef could receive any number of the parameters in the event, e.g.
sustain, speed, endSpeed, begin, end, pan, accelerate, offset, cps

it ought to use "out" as bus output argument.

the diversion is a hook to add an arbitrary function instead of a synth def.
this may be refacored later.
*/
(

~dirt.addModule('sound',
	{ |dirtEvent|
		if(~diversion.value.isNil) {
			if(~buffer.notNil) {
				// argumets could be omitted using getMsgFunc, but for making it easier to understand, we write them out
				dirtEvent.sendSynth(~instrument,  [
					bufnum: ~buffer,
					sustain: ~sustain,
					speed: ~speed,
					freq: ~freq,
					endSpeed: ~endSpeed,
					begin: ~begin,
					end: ~end,
					loop: ~loop,
					pan: ~pan,
					out: ~out
				])
			} {
				if(~instrument.isNil) {
					"module 'sound': instrument not found: %".format(~sound).postln
				} {
					// here, we just derive the arguments as necessary from the environment
					dirtEvent.sendSynth(~instrument, ~argNames)
				}
			}
		}
});


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
					vowelFreqs: [vowel.freqs],
					vowelAmps: [vowel.amps],
					vowelRqs: [vowel.rqs],
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

}, { ~shape.notNil });

~dirt.addModule('hpf',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_hpf" ++ ~numChannels,
			[
				hcutoff: ~hcutoff,
				hresonance: ~hresonance,
				out: ~out
		])

}, { ~hcutoff.notNil });

~dirt.addModule('bpf',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_bpf" ++ ~numChannels,
			[
				bandqf: ~bandf,
				bandq: ~bandq,
				out: ~out
		])

}, { ~bandf.notNil });

~dirt.addModule('crush',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_crush" ++ ~numChannels,
			[
				crush: ~crush,
				out: ~out
		])

}, { ~crush.notNil });


~dirt.addModule('coarse',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_coarse" ++ ~numChannels,
			[
				coarse: ~coarse,
				out: ~out
		])

}, { ~coarse.notNil and: { ~coarse > 1 } }); // coarse == 1 => full rate

~dirt.addModule('lpf',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_lpf" ++ ~numChannels,
			[
				cutoff: ~cutoff,
				resonance: ~resonance,
				out: ~out
		])

}, { ~cutoff.notNil });

~dirt.addModule('pshift',
	{ |dirtEvent|
		dirtEvent.sendSynth('dirt_pitch_shift' ++ ~numChannels,
			[
				psrate: ~psrate,
				sustain: ~sustain,
				out: ~out
		])
}, { ~psrate.notNil });

~dirt.addModule('envelope',
	{ |dirtEvent|
		dirtEvent.sendSynth('dirt_envelope' ++ ~dirt.numChannels,
			[
				attack: ~attack,
				hold: ~hold,
				release:~release,
				out: ~out
		])
}, { ~attack.notNil or: { ~release.notNil }});


~dirt.addModule('tremolo',
	{ |dirtEvent|
		dirtEvent.sendSynth('dirt_tremolo' ++ ~numChannels,
			[
				tremolorate: ~tremolorate,
				tremolodepth: ~tremolodepth,
				out: ~out
		])
}, { ~tremolorate.notNil });

// Phaser audio DSP effect declaration
~dirt.addModule('phaser',
	{ |dirtEvent|
		dirtEvent.sendSynth('dirt_phaser' ++ ~numChannels,
			[
				phaserrate: ~phaserrate,
				phaserdepth: ~phaserdepth,
				out: ~out
		])
}, { ~phaserrate.notNil });

);
