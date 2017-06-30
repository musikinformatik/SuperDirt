/*

How to add new effects to Tidal and SuperDirt.

This is a three step process.

1. add the desired parameters to Tidal, so it can be used
2. add a module definition to Superdirt, so it can be found when the parameter is not nil
3. add the synth def to SuperDirt, so it can be played


The following example adds a weird spectral delay
This assumes you have an instance of SuperDirt accessible via ~dirt

*/


// in Haskell

// (1) in  Sound/Tidal/Params.hs
// this adds two new  parameters "tsdelay" (float, delay time) and "xsdelay" (int, delay structure)

/*

tsdelay :: Pattern Double -> ParamPattern
tsdelay = make' VF tsdelay_p
tsdelay_p = F "tsdelay" Nothing

xsdelay :: Pattern Int -> ParamPattern
xsdelay = make' VI xsdelay_p
xsdelay_p = I "xsdelay" Nothing

*/

// ... or you can run this in the interpreter:
/*

let tsdelay = make' VF tsdelay_p
    tsdelay_p = F "tsdelay" Nothing

let xsdelay = make' VI xsdelay_p
    xsdelay_p = I "xsdelay" Nothing
*/



// in SuperCollider

// (2) add a module for superdirt
// this adds a responder for the parameter
// for more examples see synths/core-modules

(
~dirt.addModule('spectral-delay', { |dirtEvent|
	dirtEvent.sendSynth('spectral-delay' ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			xsdelay: ~xsdelay,
			tsdelay: ~tsdelay,
			sustain: ~sustain,
			out: ~out
		]
	)
}, { ~tsdelay.notNil or: { ~xsdelay.notNil } }); // play synth only if at least one of the two was given
)

// here you can see the effect order:
~dirt.modules;

// OPTIONAL: you can reorder the effects, if you want e.g. the lpf to come after the delay:
~dirt.orderModules(['spectral-delay', 'hpf', 'klm']);


// (3) make a synthdef (for more examples see core-synths)
(

var numChannels =  ~dirt.numChannels;

SynthDef("spectral-delay" ++ numChannels, { |out, tsdelay, xsdelay = 1, sustain|

	var signal, delayTime, delays, freqs, filtered;
	var size = 16;
	var maxDelayTime = 0.2;

	signal = In.ar(out, numChannels);
	delayTime = tsdelay * maxDelayTime;
	filtered = (1..size).sum { |i|
		var filterFreq = i.linexp(1, size, 40, 17000);
		var sig = BPF.ar(signal, filterFreq, 0.005);
		// the delay pattern is determined from xsdelay by bitwise-and:
		DelayN.ar(sig, maxDelayTime, i & xsdelay * (1/size) * delayTime )
	};
	signal = signal * 0.2 + (filtered * 4); // this controls wet/dry
	ReplaceOut.ar(out, signal)

}).add;
)

/*

now you should be able to write in tidal:

d1 $ sound "can*4" # tsdelay "0 0.25 0.5 0.75 1" # xsdelay "3 124 3 12 62 2"



*/

