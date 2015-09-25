/*

You can define arbitrary functions to be called from Tidal
This assumes you have stored dirt in a variable ~dirt, andyour first dirt bus in ~d1

NOTE: The interface for this may change!

*/

// d1 $ sound "tlalak bd sn sn bd"

(
~dict = (); // make a dictionary of functions
~dict[\tlalak] = {
	"hello tlalak".postln;
};
~d1.diversion = { |sound|
	~dict[sound].value(~d1)
};
)

// execute arbitrary sc code. The dirtbus is the argument
(
~dict[\tlalak] = { |dirtbus|
	// we are playing out on dirtbus.synthBus, so that we can still use global effects like delay
	Pbind(\dur, 0.02, \note, Pbrown(-15, 15, 0.3, 230.rand), \out, dirtbus.synthBus, \pan, Pfunc { 1.0.rand2 }).play
};
)