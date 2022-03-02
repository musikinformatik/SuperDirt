/*

Setting up SuperDirt to play a MIDI synth (1.) or VSTPlugin (2.) and feed audio
back into the orbit, and be able to apply effects in TidalCycles.

1. This hack shows a physical synth used in TidalCycles.
- change ~midiOut
- change the incoming channels ([3,4])

Usage:

d1 $ s "blofeld" # distort 0.2 -- here the audio from Blofeld is fed back into SuperDirt
-- (via sound card incoming 3,4 channels)
-- the envelope is controlled by TidalCycles and it's possible to use all audio effects

d1 $ s "blofeld_midi" -- fallback to pure MIDI
-- audio effects won't work and envelope is controlled by the physical synth

*/

(
~dirt.soundLibrary.addMIDISynth(\blofeld, ~midiOut, [3,4]);
)

/*

2. This hack shows SpitFire Audio Labs VST used in TidalCycles.
!!! This requires SC VSTPlugin extension installed:
https://github.com/Spacechild1/vstplugin
https://git.iem.at/pd/vstplugin

Usage:

d1 $ s "labs" # distort 0.2 -- here the audio from VST is fed back into SuperDirt
-- the envelope is controlled by TidalCycles and it's possible to use all audio effects

d1 $ s "labs_midi" -- fallback to pure MIDI
-- audio effects won't work and envelope is controlled by VST

once $ "labs_editor" -- show Labs VST GUI

*/
(
var bus = Bus.audio(s, 2);
SynthDef.new(\labs, {
	Out.ar(bus.index, VSTPlugin.ar(nil, 2));
}).add;

s.sync;

// create Synth with VST instrument
~labs = VSTPluginController(Synth(\labs));
~labs.open("/Library/Audio/Plug-Ins/VST/LABS.vst", editor: true, verbose: true);

~dirt.soundLibrary.addMIDISynth(\labs, ~labs.midi, bus.index);
~dirt.soundLibrary.addSynth(\labs_editor, (play: {
	topEnvironment[\labs].editor;
}));

// wait for SuperDirt to initialize routing, and move the Labs VST synth before the orbits
AppClock.sched(0, {
    ~labs.synth.group.moveNodeToHead(~labs.synth);
	nil;
});
)
