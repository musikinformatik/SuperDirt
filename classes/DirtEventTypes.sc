/*

This class adds event types to the global event library. They can be played from sclang.

*/

DirtEventTypes {
	classvar <midiEvent;

	*initClass {

		// allows to play events in superdirt from sclang

		Event.addEventType(\dirt, {
			var keys, values;
			var dirt = ~dirt ? SuperDirt.default;
			if(dirt.isNil) {
				Error("dirt event: no dirt instance found.\n\n// You could try:\nSuperDirt.default = ~dirt;").throw;
			};
			~delta = ~delta ?? { ~stretch.value * ~dur.value };
			~latency = ~latency ?? { dirt.server.latency };
			if(~n.isArray) {
				keys = currentEnvironment.keys.asArray;
				values = keys.collect(_.envirGet).flop;
				values.do { |each|
					var e = Event(parent: currentEnvironment);
					keys.do { |key, i| e.put(key, each.at(i)) };
					dirt.orbits.wrapAt(e[\orbit] ? 0).value(e)
				}
			} {
				dirt.orbits.wrapAt(~orbit ? 0).value(currentEnvironment)
			}
		});

		// corrected event type, fixing a few things from the standard \midi event type


	midiEvent = (
			midiOutNotFoundError: DirtPartTimeError(2, "midi device is nil."),
			play: #{

				var freq, lag, sustain;
				var args, midiout, hasGate, midicmd, latency, chan;
				var sendNRPN, schedmidi, schedmidicmd, donecmd;
				var hasNote = (~n != \none or: {~note.notNil});
				var midiCommandPending = ~midicmd.notNil;
				var nrpnMSB, nrpnLSB, valMSB, valLSB;
				var ctlNum, control, num, val, note;

				midiout = ~midiout.value;

				if(midiout.isNil) {
					~midiOutNotFoundError.throw
				};
				midicmd = ~midicmd;
				~chan = ~midichan ? 0;
				chan = ~chan;

				lag = ~lag + (~latency ? 0);
				latency = lag; // for now.

				schedmidi = if(latency == 0.0) {
					{|f| f.value }
				} {
					{|f| thisThread.clock.sched(latency, f) }
				};

				donecmd = { |cmd|
					if(midiCommandPending) { midiCommandPending = (midicmd !== cmd) }
				};

				schedmidicmd = { |cmd|
					var func;
					func = Event.default[\midiEventFunctions][cmd];
					args = func.valueEnvir.asCollection;
					schedmidi.value { midiout.performList(cmd, args) };
					donecmd.value(cmd);
				};

				// guess MIDI events from parameters
				if(~ccn.notNil and: {~ccv.notNil }) {
					ctlNum = ~ccn; // TODO - also check for ~ctlNum ?
					control = ~ccv;
					schedmidi.value({ midiout.control(chan, ctlNum, control) });
				};

				if(~nrpn.notNil) {
					~val = ~val ? 0;
					nrpnLSB = ~nrpn % 128;
					nrpnMSB = (~nrpn - nrpnLSB) / 128;
					valLSB  = ~val % 128;
					valMSB  = (~val - valLSB) / 128;
					schedmidi.value({
						midiout.control(chan, 99, nrpnMSB);
						midiout.control(chan, 98, nrpnLSB);
						midiout.control(chan, 6,  valMSB);
						midiout.control(chan, 38, valLSB);
					});
				};

				if(~progNum.notNil)   { num = ~progNum;   donecmd.value(\program); schedmidi.value({ midiout.program(chan, num) })};
				if(~midibend.notNil)  { val = ~midibend;  donecmd.value(\bend);    schedmidi.value({ midiout.bend(chan, val)    })};
				if(~miditouch.notNil) { val = ~miditouch; donecmd.value(\touch);   schedmidi.value({ midiout.touch(chan, val)   })};

				if (hasNote) {
					freq = ~freq.value;
					~midinote = (freq.cpsmidi).round(1).asInteger;
					// Assume aftertouch means no noteOn, for now..
					if(~polyTouch.notNil) {
						val = ~polyTouch;
						note = ~midinote;
						schedmidi.value({ midiout.polyTouch(chan, note, val) })
					} {
						~amp = ~amp.value;
						sustain = ~sustain = ~sustain.value;
						if(~uid.notNil and: { midiout.notNil }) {
							~uid = midiout.uid    // mainly for sysex cmd
						};
						hasGate = ~hasGate ? true; // TODO
						schedmidicmd.value(\noteOn);
						if(hasGate) {
							thisThread.clock.sched(sustain + latency, {
								midiout.noteOff(*args);
							})
						}
					}
				};

				if(midiCommandPending) { schedmidicmd.value(midicmd) };

				true // always return something != nil to end processing in DirtEvent
			}
		)
	}
}
