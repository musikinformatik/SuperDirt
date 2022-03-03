/*
Setting up SuperDirt to play a hardware MIDI synth (Hack 1) or VSTPlugin (Hack 2)
and feed audio back into the orbit, and be able to apply effects in TidalCycles.
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
	if (metaData.isNil) { metaData = (); };
	if (event.notNil) { midiEvent.putAll(event) };
	// clean up previous gate
	if (metaDataEvents.notNil) {
		metaDataEvents.flat.do { |value|
			if (value.isNumber) {
				dirt.server.sendMsg(\n_free, value);
			} {
				value.free;
			};
		};
		dirt.soundLibrary.metaDataEvents[name] = nil;
	};

	dirt.soundLibrary.addSynth(name, (play: { |dirtEvent|
		if (bus.notNil) {
			var gate;
			~synthGroup = dirtEvent.orbit.group;
			~out = bus;
			if (metaData[\midi_synth_gate].isNil) {
				metaData[\midi_synth_gate] = Synth("midi_synth_gate" ++ dirt.numChannels, [out: dirtEvent.orbit.dryBus.index, from: bus], ~synthGroup);
			};
			gate = metaData[\midi_synth_gate];
			dirtEvent.modules.do {|module|
				if (module.test.value and: {module.name != 'sound'}) {
					if (metaData[module.name].isNil) {
						metaData[module.name] = ~synthID = dirt.server.nextNodeID;
						module.func.value(dirtEvent);
						gate.group.moveNodeToTail(gate);
					} {
						module.func.value((sendSynth: { |self, instrument, args|
							args.asControlInput.flop.do { |each|
								dirt.server.sendMsg(\n_set, metaData[module.name], *each.asOSCArgArray);
							};
						}));
					};
				} {
					if (metaData[module.name].notNil) {
						dirt.server.sendMsg(\n_free, metaData[module.name]);
						metaData.removeAt(module.name);
					};
				};
			};
		};
		~midiout = device;
		midiEvent[\play].value;
		dirt.server.makeBundle(~latency, {
			dirtEvent.orbit.globalEffects.do { |x| x.set(currentEnvironment) };
		});
		true;
	}), appendToExisting, false, metaData);
};

/*
| Hack 1 | This hack shows a physical synth used in TidalCycles.
- change midiOut port
- change the incoming channel index (2)

Usage:

d1 $ s "blofeld" # lpf 200 # distort 0.2 # room 0.5 # size 0.8
-- here the audio from hardware MIDI synth is fed back into SuperDirt
-- (via sound card channels 2,3) and it's possible to use all audio effects

*/

// MIDIClient.init;
midiOut = MIDIClient.destinations[0];
// midiOut = MIDIOut.findPort("deviceName", "portName")
~addMIDISynth.(~dirt, \blofeld, midiOut, 2);

/*
| Hack 2 | This hack shows SpitFire Audio Labs VST used in TidalCycles.
!!! This requires SC VSTPlugin extension installed:
https://github.com/Spacechild1/vstplugin
https://git.iem.at/pd/vstplugin

Usage:

d1 $ s "labs" # lpf 200 # distort 0.2 # room 0.5 # size 0.8
-- here the audio from VST is fed back into SuperDirt and it's possible to use all audio effects

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
