/*

Setting up SuperDirt to play a MIDI synth (or VSTPlugin) and feed audio
back into the orbit, and be able to apply effects in TidalCycles.

This hack shows SpitFire Audio Labs VST used in TidalCycles.

d1 $ s "labs" # distort 0.2 -- here the audio from VST is fed back into SuperDirt
-- the envelope is controlled by TidalCycles and it's possible to use all audio effects

d1 $ s "labs_midi" -- fallback to pure MIDI
-- audio effects won't work and envelope is controlled by VST

!!! this hack requires SC VSTPlugin extension installed:
https://github.com/Spacechild1/vstplugin
https://git.iem.at/pd/vstplugin

*/
(
~labs_bus = Bus.audio(s, 2);
SynthDef.new(\labs, {
	Out.ar(~labs_bus.index, VSTPlugin.ar(nil, 2));
	// to feed physical MIDI synth output back into SuperDirt use instead:
	// Out.ar(~labs_bus.index, In.ar([3, 4]));
}).add;
SynthDef.new(\labs_bridge, { arg out = 0;
	Out.ar(out, In.ar(~labs_bus.index, 2));
}).add;

s.sync;

// create Synth with VST instrument
~labs = VSTPluginController(Synth(\labs));
~labs.open("/Library/Audio/Plug-Ins/VST/LABS.vst", editor: true, verbose: true);

// uncomment, to forward all MIDI messages into Labs VST:
// MIDIFunc.noteOn({ |vel, pitch|
// 	~labs.midi.noteOn(0, pitch, vel);
// });
// MIDIFunc.noteOff({ |vel, pitch|
// 	~labs.midi.noteOff(0, pitch, vel);
// });

~dirt.soundLibrary.addMIDISynth(\labs, ~labs.midi, ~labs.synth);
~dirt.soundLibrary.addSynth(\labs_editor, (play: {
	topEnvironment[\labs].editor;
}));
)
