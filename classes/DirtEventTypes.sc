/*

This class adds event types to the global event library. They can be played from sclang.

*/

DirtEventTypes {

	*initClass {

		// allows to play events in superdirt from sclang

		Event.addEventType(\dirt, {
			var keys, values;
			var dirt = ~dirt ? SuperDirt.default;
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

		Event.addEventType(\tidalmidi, #{|server|

			var freqs, lag, sustain, strum;
			var args, midiout, hasGate, midicmd, latency;
			midicmd = ~midicmd;

			if(midicmd.isNil) {
				if(~ccn.notNil) { midicmd = \control; ~ctlNum = ~ccn };
				if(~ccv.notNil) { midicmd = \control; ~control = ~ccv };
				if(~progNum.notNil) { midicmd = \program };
				if(~polyTouch.notNil) { midicmd = \polyTouch };
				if(~midibend.notNil) { midicmd = \bend; ~val = ~midibend; };
				if(~miditouch.notNil) { midicmd = \touch; ~val = ~miditouch; };
				if(midicmd.isNil) { midicmd = \noteOn }; // if still nil
			};

			freqs = ~freq.value;

			~amp = ~amp.value;
			~midinote = (freqs.cpsmidi).round(1).asInteger;
			strum = ~strum;
			lag = ~lag + (~latency ? 0);
			sustain = ~sustain = ~sustain.value;
			midiout = ~midiout.value;
			~uid ?? { ~uid = midiout.uid };  // mainly for sysex cmd
			hasGate = ~hasGate ? true; // TODO

			~ctlNum = ~ctlNum ? 0;
			~chan = ~midiChan ? 0;

			args = ~midiEventFunctions[midicmd].valueEnvir.asCollection;

			latency = i * strum + lag;

			if(latency == 0.0) {
				midiout.performList(midicmd, args)
			} {
				thisThread.clock.sched(latency, {
					midiout.performList(midicmd, args);
				})
			};
			if(hasGate and: { midicmd === \noteOn }) {
				thisThread.clock.sched(sustain + latency, {
					midiout.noteOff(*args)
				});
			};

		})
	}

}