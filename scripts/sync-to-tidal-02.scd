
// cycle test
// this may lead to weird effects
(
var quant = 1.0;
~dirt.receiveAction = { |e|
	var cycle = e[\cycle];
	var cps = e[\cps];
	var latency = e[\latency];
	cycle !? {
		if(cycle % quant == 0) { // set clock only quant in cycle
			TempoClock.default.beats = cycle;
		};
	};
	cps !? {
		TempoClock.default.tempo = cps;
	};
	latency !? {
		Server.default.latency = latency;
	}
}
);




(
SynthDef(\sinegrain,
    { | out=0, freq=440, sustain=0.05 |
        var env;
        env = EnvGen.kr(Env.perc(0.01, sustain, 0.2), doneAction: Done.freeSelf);
        Out.ar(out, SinOsc.ar(freq, 0.5pi, env))
    }).add;


Pbind(\instrument, \sinegrain, \note, Pseq([6, [3, 5, 8], 2, 0], inf), \dur, 0.25).play(quant: 2);
)


// reset to normal:
(
~dirt.receiveAction = nil;
TempoClock.default.tempo = 1;
)

