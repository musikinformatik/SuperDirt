/*
Setting up SuperDirt to play a hardware MIDI synth (Hack 1) or VSTPlugin (Hack 2)
and feed audio back into the orbit, and be able to apply effects/panning/etc in TidalCycles.
*/
(
var numChannels = ~dirt.numChannels;

SynthDef("dirt_gate_cont" ++ numChannels, { |out, from, pan = 0, gate=1, fadeTime = 0.01, amp = 1, gain = 1, overgain = 0|
	var signal = In.ar(from, numChannels);
	var env = EnvGen.kr(Env.asr(fadeTime, 1.0, fadeTime, \sin), gate, doneAction: 14);
	amp = amp * pow(gain.min(2) + overgain, 4);
	signal = DirtPan.ar(signal, numChannels, pan) * env * amp;
	OffsetOut.ar(out, signal);
	ReplaceOut.ar(in, Silent.ar(numChannels));
}, [\ir, \ir, \kr]).add;

~addMIDISynth = { |dirt, name, device, bus, event, appendToExisting = false, metaData|
	var midiEvent = DirtEventTypes.midiEvent.copy;
	var lastEventSecs = 0, lastDelta = 0;
	var playModules = { |dirtEvent, metaData|
		var orbit = dirtEvent.orbit;
		dirtEvent.modules.do {|module|
			if (module.test.value and: {module.name != 'sound'}) {
				if (metaData[module.name].isNil) {
					~synthID = orbit.server.nextNodeID;
					metaData.put(module.name, ~synthID);
					module.func.value(dirtEvent);
					if (metaData[\gate].notNil) {
						metaData[\gate].group.moveNodeToTail(metaData[\gate]);
					};
				} {
					module.func.value((sendSynth: { |self, instrument, args|
						args = args ?? { dirtEvent.getMsgFunc(instrument).valueEnvir };
						args.asControlInput.flop.do { |each|
							dirt.server.sendMsg(\n_set, metaData[module.name], *each.asOSCArgArray);
						};
					}));
				};
			} {
				if (metaData[module.name].notNil) {
					orbit.server.sendMsg(\n_free, metaData[module.name]);
					metaData.removeAt(module.name);
				};
			};
		};
	};
	var freeSynths = { |fadeTime = 0.01|
		var metaDataEvents = dirt.soundLibrary.metaDataEvents[name];
		if (metaDataEvents.notNil) {
			metaDataEvents.flat.do { |metaData|
				if (metaData[\gate].notNil) {
					metaData[\gate].set(\gate, 0);
				};
				metaData.copy.keysDo { |key|
					metaData.removeAt(key);
				};
			};
		};
	};
	freeSynths.value;
	if (metaData.isNil) { metaData = (); };
	if (event.notNil) { midiEvent.putAll(event) };

	dirt.soundLibrary.addSynth(name, (play: { |dirtEvent|
		var delta = ~delta;
		var fadeTime = ~fadeTime;
		lastDelta = delta;
		lastEventSecs = SystemClock.seconds;
		if (bus.notNil) {
			var gateArgs = [out: dirtEvent.orbit.dryBus.index, from: bus, pan: ~pan, fadeTime: fadeTime, amp: ~amp, gain: ~gain, overgain: ~overgain];
			if (metaData[\group].isNil) {
				dirtEvent.prepareSynthGroup;
				metaData[\group] = ~synthGroup;
			} { ~synthGroup = metaData[\group]; };
			~out = bus;
			if (metaData[\gate].isNil) {
				metaData[\gate] = Synth("dirt_gate_cont" ++ dirt.numChannels, gateArgs, ~synthGroup);
			} {
				metaData[\gate].set(*gateArgs);
			};
			playModules.value(dirtEvent, metaData);
		};
		~midiout = device;
		midiEvent[\play].value;
		dirt.server.makeBundle(~latency, {
			dirtEvent.orbit.globalEffects.do { |x| x.set(currentEnvironment) };
		});
		// if we don't receive next event, free the synths
		SystemClock.sched((delta + ~latency), {
			if ((SystemClock.seconds - lastEventSecs) > delta and: { delta == lastDelta }) {
				freeSynths.value(fadeTime);
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
