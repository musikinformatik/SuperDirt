



// read input from another orbit


(
var busses = ~dirt.orbits.collect { |x| x.dryBus };

SynthDef(\readorb, { |out, amp = 1, n = 0| // number
	var bus, sound;

	bus = Select.kr(n, busses);
	sound = InFeedback.ar(bus, ~dirt.numChannels);
	//sound = CombL.ar(sound, 0.2, 0.03, 1);

	Out.ar(out,
		sound * (amp * 2.5)
	)
}).add;
);

/*
// in tidal, e.g.:


d1 $ sound "can bd hh*8 bd" # pan "0"

d2 $ sound "readorb:0 bd" # pan "1" # orbit "1" # delay "1" # delaytime "0.15" # delayfeedback "0.5" # bandf "{90 200 9000}/3" # bandq "10"

*/
