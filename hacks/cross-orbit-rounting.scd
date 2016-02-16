



// read input from another orbit


(
var busses = ~dirt.orbits.collect { |x| x.dryBus };

SynthDef(\orb, { |out, amp = 1, n = 0| // number
	var bus, sound;

	bus = Select.kr(n, busses);
	sound = InFeedback.ar(bus, ~dirt.numChannels);

	Out.ar(out,
		sound * amp
	)
}).add;
);
