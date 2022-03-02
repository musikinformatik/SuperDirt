/*
Setting up SuperDirt to play a MIDI synth (1.) or VSTPlugin (2.) and feed audio
back into the orbit, and be able to apply effects in TidalCycles.
*/
(
var midiOut, bus;
var numChannels = ~dirt.numChannels;

SynthDef("midi_synth_bridge" ++ numChannels, { |out, from, amp = 1|
	var signal = In.ar(from, numChannels);
	Out.ar(out, signal * amp);
}, [\ir, \ir, \kr]).add;

~addMIDISynth = { |dirt, name, device, bus, event, appendToExisting = false, metaData|
	var metaDataEvents = dirt.soundLibrary.metaDataEvents[name];
	var midiEvent = DirtEventTypes.midiEvent.copy;
	if (metaData.isNil) { metaData = (\bridge: nil); };
	if (event.notNil) { midiEvent.putAll(event) };
	// clean up previous bridge
	if (metaDataEvents.notNil and: { metaDataEvents.last[\bridge].notNil }) {
		metaDataEvents.last[\bridge].free;
		metaDataEvents.last.removeAt(\bridge);
	};

	dirt.soundLibrary.addSynth(name, (play: {
		var orbit = (dirt.orbits @@ ~orbit);
		~midiout = device;
		// free the permanent bridge synth, and let each event create a temp bridge
		if (metaData[\bridge].notNil) {
			metaData[\bridge].free;
			metaData.removeAt(\bridge);
		};
		midiEvent[\play].value;
		~s = ("midi_synth_bridge" ++ dirt.numChannels).asSymbol;
		~from = bus;
		// force some fadeInTime
		~begin = if (~begin == 0, { ~begin = 0.001; });
		DirtEvent(orbit, dirt.modules, currentEnvironment).play;
	}), appendToExisting, false, metaData);

	dirt.soundLibrary.addSynth((name.asString ++ "_midi").asSymbol, (play: {
		var orbit = (dirt.orbits @@ ~orbit);
		~midiout = device;
		// create a permanent bridge synth (has to be after the VST synth)
		if (metaData[\bridge].isNil and: { bus.notNil }) {
			metaData[\bridge] = Synth("midi_synth_bridge" ++ dirt.numChannels, [from: bus], addAction: \addToTail);
		};
		midiEvent[\play].value;
	}), appendToExisting, false, metaData);
};

/*
1. This hack shows a physical synth used in TidalCycles.
- change midiOut
- change the incoming channels (2)

Usage:

d1 $ s "blofeld" # distort 0.2 -- here the audio from Blofeld is fed back into SuperDirt
-- (via sound card incoming 2,3 channels)
-- the envelope is controlled by TidalCycles and it's possible to use all audio effects

d1 $ s "blofeld_midi" -- fallback to pure MIDI
-- audio effects won't work and envelope is controlled by the physical synth

*/

// MIDIClient.init;
midiOut = MIDIClient.destinations[0];
// midiOut = MIDIOut.findPort("deviceName", "portName")
~addMIDISynth.(~dirt, \blofeld, midiOut, 2);

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
bus = Bus.audio(s, numChannels);
SynthDef.new(\labs, {
	Out.ar(bus.index, VSTPlugin.ar(nil, numChannels));
}).add;

s.sync;

// create Synth with VST instrument
~labs = VSTPluginController(Synth(\labs));
~labs.open("/Library/Audio/Plug-Ins/VST/LABS.vst", editor: true, verbose: true);

~addMIDISynth.(~dirt, \labs, ~labs.midi, bus.index);
~dirt.soundLibrary.addSynth(\labs_editor, (play: {
	topEnvironment[\labs].editor;
}));

// wait for SuperDirt to initialize routing, and move the Labs VST synth before the orbits
AppClock.sched(0, {
    ~labs.synth.group.moveNodeToHead(~labs.synth);
	nil;
});
)
