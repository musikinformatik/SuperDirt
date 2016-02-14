/*

out of order, needs fixing

*/

(
thisProcess.removeOSCRecvFunc(~oscFunc);
~oscFile !? { ~oscFile.close };

~oscFile = File("~/osc-log.txt".standardizePath, "w");

~oscFunc = { |x, time|
	if(x[0] == '/play2') {
		~oscFile <<<* ([time] ++ x[1..]) << Char.nl
	};

};

thisProcess.addOSCRecvFunc(~oscFunc);
)

// stop it:
(
thisProcess.removeOSCRecvFunc(~oscFunc);
~oscFile !? { ~oscFile.close };
)


// incrementally play it:
(
~playLog = { |path, startFrom = 0.0, orbit| // seconds into the log
	var file = File.open(path.standardizePath, "r");
	var getArgs = { |str| str.split($,).collect(_.interpret) };
	var nextLine = { getArgs.(file.getLine ? "") };
	orbit = orbit ? ~d1;
	fork {
		var list, time1, time2;
		list = nextLine.value ? [];
		time1 = list[0];
		while {
			list = nextLine.value;
			time2 = list[0];
			time2.notNil
		} {
			if(startFrom <= 0) {
				orbit.value([\latency, s.latency] ++ list[1..].postln);
				(time2 - time1).wait;
			} {
				startFrom = startFrom - (time2 - time1);
			};
			time1 = time2;
		};
		file.close;
		"---- finished ----".postln;
	};
	CmdPeriod.doOnce { file.close };
};
~playLog.("~/osc-log.txt");
)



// or read it all, to take a closer look ...
(
File.use("~/osc-log.txt".standardizePath, "r", { |file|
	~oscData = file.readAllString.split(Char.nl).collect(_.split($,));
	~oscData = ~oscData.deepCollect(2, _.interpret).drop(-1)
});
~oscData.cs;
);


/*
Parameters:

[ 'latency', 'cps', 'sound', 'offset', 'begin', 'end', 'speed', 'pan', 'velocity', 'vowel', 'cutoff', 'resonance', 'accelerate', 'shape', 'krio', 'gain', 'cut', 'delay', 'delaytime', 'delayfeedback', 'crush', 'coarse', 'hcutoff', 'hresonance', 'bandqf', 'bandq', 'unit' ]

*/

