/*
Setting up SuperDirt to play a hardware MIDI synth (Hack 1) or VSTPlugin (Hack 2)
and feed audio back into the orbit, and be able to apply effects in TidalCycles.
*/
(
var numChannels = ~dirt.numChannels;

SynthDef("midi_synth_gate" ++ numChannels, { |out, from, amp = 1, pan = 0|
	var signal = In.ar(from, numChannels);
	signal = DirtPan.ar(signal, numChannels, pan);
	Out.ar(out, signal * amp);
}, [\ir, \ir, \kr]).add;

~addMIDISynth = { |dirt, name, device, bus, event, appendToExisting = false, metaData|
	var midiEvent = DirtEventTypes.midiEvent.copy;
	var lastEventSecs = 0, lastDelta = 0;
	var cleanup = {
		var metaDataEvents = dirt.soundLibrary.metaDataEvents[name];
		if (metaDataEvents.notNil) {
			metaDataEvents.flat.do { |md|
				md.copy.keysValuesDo { |key, val|
					if (val.isNumber) {
						dirt.server.sendMsg(\n_free, val);
					} {
						if ( val.respondsTo(\free)) { val.free; };
					};
					md.removeAt(key);
				};
			};
		};
	};
	cleanup.value;
	if (metaData.isNil) { metaData = (); };
	if (event.notNil) { midiEvent.putAll(event) };

	dirt.soundLibrary.addSynth(name, (play: { |dirtEvent|
		var delta = ~delta;
		lastDelta = delta;
		lastEventSecs = SystemClock.seconds;
		if (bus.notNil) {
			var gateSynth;
			var gateArgs = [out: dirtEvent.orbit.dryBus.index, from: bus, pan: ~pan];
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
						~synthID = dirt.server.nextNodeID;
						metaData.put(module.name, ~synthID);
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
		// if we don't receive next event, free the synths
		SystemClock.sched((delta + ~latency), {
			if ((SystemClock.seconds - lastEventSecs) > delta and: { delta == lastDelta }) {
				cleanup.value;
			};
			nil;
		});
		true;
	}), appendToExisting, false, metaData);
};
)
/*
| Hack 1 | This hack shows a hardware midi synth used in TidalCycles.
- change "deviceName" and "portName"
- change inCh number

Usage:

d1 $ s "my_hardware_synth" # lpf 200 # distort 0.2 # room 0.5 # size 0.8
-- here the audio from hardware MIDI synth is fed back into SuperDirt
-- (via sound card channels 2,3) and it's possible to use all audio effects

*/
(
fork {
	var deviceName = "deviceName";
	var portName = "portName";
	var inCh = [0, 1];
	if (MIDIClient.initialized.not) { MIDIClient.init; };
	if (MIDIOut.findPort(deviceName, portName).notNil) {
		var midiOut = MIDIOut.newByName(deviceName, portName);
		var hwBus = Bus.audio(s, 2);
		var hwSynth;

		SynthDef(\midi_synth_in, {
			Out.ar(hwBus.index, SoundIn.ar(inCh));
		}).add;

		// sync synthdef
		s.sync;

		hwSynth = Synth(\midi_synth_in);

		~addMIDISynth.(~dirt, \my_hardware_synth, midiOut, hwBus.index);

		// move to head after SuperDirt inits routing
		SystemClock.sched(0.05, {
			hwSynth.group.moveNodeToHead(hwSynth);
			nil;
		});
	};
};
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
fork {
	var vstPaths = (
		\mac: "/Library/Audio/Plug-Ins/VST/LABS.vst",
	);

	if (vstPaths[thisProcess.platform.name].notNil) {
		var vstPath = vstPaths[thisProcess.platform.name];
		var vstBus = Bus.audio(s, 2);

		SynthDef(\labs, {
			Out.ar(vstBus.index, VSTPlugin.ar(nil, 2));
		}).add;

		// sync synthdef
		s.sync;

		// create Synth with VST instrument
		~labs = VSTPluginController(Synth(\labs));
		~labs.open(vstPath, editor: true, verbose: false);

		~addMIDISynth.(~dirt, \labs, ~labs.midi, vstBus.index);
		~dirt.soundLibrary.addSynth(\labs_editor, (play: {
			topEnvironment[\labs].editor;
		}));

		// move to head after SuperDirt inits routing
		SystemClock.sched(0.05, {
			~labs.synth.group.moveNodeToHead(~labs.synth);
			nil;
		});
	};
};
)
