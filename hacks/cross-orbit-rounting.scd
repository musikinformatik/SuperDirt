



// read input from another orbit


(
var busses = ~dirt.orbits.collect { |x| x.dryBus };

SynthDef(\orb, { |out, amp = 1, n = 0| // number
	var bus, sound;

	bus = Select.kr(n, busses);
	sound = InFeedback.ar(bus, ~dirt.numChannels);
	//sound = CombL.ar(sound, 0.2, 0.03, 1);

	Out.ar(out,
		sound * (amp * 2.5)
	)
}).add;
);
