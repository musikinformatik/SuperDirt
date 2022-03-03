/*
Setting up SuperDirt to play a hardware MIDI synth (Hack 1) or VSTPlugin (Hack 2)
and feed audio back into the orbit, and be able to apply effects in TidalCycles.
*/
(
var numChannels = ~dirt.numChannels;

SynthDef("midi_synth_gate" ++ numChannels, { |out, from, amp = 1|
	var signal = In.ar(from, numChannels);
	Out.ar(out, signal * amp);
}, [\ir, \ir, \kr]).add;

~addMIDISynth = { |dirt, name, device, bus, event, appendToExisting = false, metaData|
	var metaDataEvents = dirt.soundLibrary.metaDataEvents[name];
	var midiEvent = DirtEventTypes.midiEvent.copy;
	if (metaData.isNil) { metaData = (); };
	if (event.notNil) { midiEvent.putAll(event) };
	if (metaDataEvents.notNil) {
		metaDataEvents.flat.do { |value|
			if (value.isNumber) {
				dirt.server.sendMsg(\n_free, value);
			} {
				if ( value.respondsTo(\free)) { value.free; };
			};
		};
		dirt.soundLibrary.metaDataEvents[name] = nil;
	};

	dirt.soundLibrary.addSynth(name, (play: { |dirtEvent|
		if (bus.notNil) {
			var gateSynth;
			var gateArgs = [out: dirtEvent.orbit.dryBus.index, from: bus];
			~synthGroup = dirtEvent.orbit.group;
			~out = bus;
			if (metaData[\midi_synth_gate].isNil) {
				metaData[\midi_synth_gate] = Synth("midi_synth_gate" ++ dirt.numChannels, gateArgs, ~synthGroup);
			} {
				metaData[\midi_synth_gate].set(*gateArgs);
			};
			gateSynth = metaData[\midi_synth_gate];
			dirtEvent.modules.do {|module|
				if (module.test.value and: {module.name != 'sound'}) {
					if (metaData[module.name].isNil) {
						metaData[module.name] = ~synthID = dirt.server.nextNodeID;
						module.func.value(dirtEvent);
						gateSynth.group.moveNodeToTail(gateSynth);
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
)
/*
| Hack 1 | This hack shows a hardware midi synth used in TidalCycles.
- change inBus number
- change "deviceName" and "portName" for MIDIOut.findPort

Usage:

d1 $ s "my_hardware_synth" # lpf 200 # distort 0.2 # room 0.5 # size 0.8
-- here the audio from hardware MIDI synth is fed back into SuperDirt
-- (via sound card channels 2,3) and it's possible to use all audio effects

*/
(
var inBus = 2;
var midiOut;
if (MIDIClient.initialized.not) { MIDIClient.init; };
midiOut = MIDIOut.findPort("deviceName", "portName");
if (midiOut.notNil) {
	~addMIDISynth.(~dirt, \my_hardware_synth, midiOut, inBus);
}
)
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
(
s.waitForBoot {
	var vstPaths = (
		\mac: "/Library/Audio/Plug-Ins/VST/LABS.vst",
	);

	if (vstPaths[thisProcess.platform.name].notNil) {
		var vstPath = vstPaths[thisProcess.platform.name];
		var vstBus = Bus.audio(s, 2);

		SynthDef.new(\labs, {
			Out.ar(vstBus.index, VSTPlugin.ar(nil, 2));
		}).add;

		s.sync;

		// create Synth with VST instrument
		~labs = VSTPluginController(Synth(\labs));
		~labs.open(vstPath, editor: true, verbose: false);

		~addMIDISynth.(~dirt, \labs, ~labs.midi, vstBus.index);
		~dirt.soundLibrary.addSynth(\labs_editor, (play: {
			topEnvironment[\labs].editor;
		}));

		// wait for SuperDirt to initialize routing, and move the Labs VST synth before the orbits
		AppClock.sched(0, {
		    ~labs.synth.group.moveNodeToHead(~labs.synth);
			nil;
		});
	};
};
)
