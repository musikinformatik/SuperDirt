/*

You can define arbitrary functions to be called from Tidal
This assumes you have stored dirt in a variable ~dirt

NOTE: The interface for this may change!

*/

// d1 $ sound "tlalak bd"
(
~dirt.functions[\tlalak] = {
	"hello tlalak".postln;
};
)

// execute arbitrary sc code. The dirtbus is the argument
(
~dirt.functions[\tlalak] = { |dirtbus|
	// we are playing out on dirtbus.synthBus, so that we can still use global effects like delay
	Pbind(\dur, 0.01, \note, Pbrown(-15, 15, 0.3, 2130.rand), \out, dirtbus.synthBus).play
};
)