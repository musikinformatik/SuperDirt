/*

here is a brief example of how you can use the full supercollider pitch model from tidal


*/

// add these parameters to tidal:
/*

let (degree, degree_p) = pF "degree" (Nothing)
    (note, note_p) = pF "note" (Nothing)
    (ctranspose, ctranspose_p) = pF "ctranspose" (Nothing)
    (mtranspose, mtranspose_p) = pF "mtranspose" (Nothing)
    (harmonic, harmonic_p) = pF "harmonic" (Nothing)
    (detune, detune_p) = pF "detune" (Nothing)
    (scale, scale_p) = pS "scaleName" (Nothing)
    (tuning, tuning_p) = pS "tuning" (Nothing)
    (stepsPerOctave, stepsPerOctave_p) = pI "stepsPerOctave" (Nothing)
    (octaveRatio, octaveRatio_p) = pF "octaveRatio" (Nothing)

*/

// d1 $ slow 2 $ s "gabor*8" # degree "0 1 2 3 4 5 6 7 8 9" # octave "4" # mtranspose "{0 1}/8"



// change this in sclang, you can use the above parameters apart from scale and tuning


(
~dirt.orbits.do { |x|
	var event = x.defaultParentEvent;
	var pitchEvent = Event.partialEvents.pitchEvent.copy;
	[\freq, \midinote, \octave].do(event.removeAt(_));
	event.parent = pitchEvent;
};
)


// if we want to pick scales and tunings by name
// this works only when synths use \freq as argument
(
~dirt.orbits.do { |x|
	var event = x.defaultParentEvent;
	var pitchEvent = Event.partialEvents.pitchEvent.copy;
	var scale;
	pitchEvent.use {
		~freq = {
			~scaleName !? {
				scale = Scale.at(~scaleName);
				scale !? {
					~scale = scale;
					~tuning !? {
						~scale.tuning = Tuning.at(~tuning);
					}
				}
			};
			(~midinote.value + ~ctranspose).midicps * ~harmonic;
		};

		[\freq, \midinote, \octave].do(event.removeAt(_));

		event.parent = pitchEvent;
	}
};
)

// d1 $ slow 2 $ s "gabor*8" # degree "0 1 2 3 4 5 6 7 8 9" # octave "4" # mtranspose "{0 1}/8" # scale "locrianMajor"


