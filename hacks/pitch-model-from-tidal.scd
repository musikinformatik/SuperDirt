/*

here is a brief example of how you can use the full supercollider pitch model from tidal


*/

// add these parameters to tidal:
/*

let (degree, degree_p) = pF "degree" (Nothing)
    (ctranspose, ctranspose_p) = pF "ctranspose" (Nothing)
    (mtranspose, mtranspose_p) = pF "mtranspose" (Nothing)
    (gtranspose, gtranspose_p) = pF "gtranspose" (Nothing)
    (harmonic, harmonic_p) = pF "harmonic" (Nothing)
    (detune, detune_p) = pF "detune" (Nothing)
    (scale, scale_p) = pS "scaleName" (Nothing)
    (tuning, tuning_p) = pS "tuningName" (Nothing)
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
	var scale, tuning;
	pitchEvent.use {
		~freq = {
			if(~n != 0) { ~note = ~n }; // interpret n as note (might be also degree)
			~scaleName !? {
				scale = Scale.at(~scaleName);
				scale !? {
					~scale = scale;
					~tuningName !? {
						tuning = Tuning.at(~tuningName);
						tuning !? { ~scale = ~scale.copy; ~scale.tuning = tuning };
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

/*

d1 $ slow 2 $ s "gabor*8" # degree "0 1 2 3 4 5 6 7 8 9" # octave "4" # mtranspose "{0 1}/8" # scale "locrianMajor"

d1 $ slow 2 $ s "gabor*8" # degree "0 1 2 3 4 5 6 7" # scale "ritusen"

-- tunings, very subtle differences

d1 $ slow 2 $ s "gabor*8" # degree "0 1 2 3 4 5 6 7" # scale "ritusen" # tuning "young"

d1 $ slow 2 $ s "gabor*8" # degree "0 1 2 3 4 5 6 7" # scale "ritusen" # tuning "just"

*/

