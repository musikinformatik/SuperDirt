(
thisProcess.removeOSCRecvFunc(~oscFunc);
~oscFile !? { ~oscFile.close };

~oscFile = File("~/osc-log.txt".standardizePath, "w");

~oscFunc = { |x, time|
	if(x[0] == '/play') {
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

// read it again:
(
File.use("~/osc-log.txt".standardizePath, "r", { |file|
	~oscData = file.readAllString.split(Char.nl).collect(_.split($,));
	~oscData = ~oscData.deepCollect(2, _.interpret)
})
);


// play it again:
(
fork {
	~oscData.do { |list, i|
		var time, args, nextTime;
		#time ... args = list;
		~d1.value2(s.latency, *args);
		nextTime = ~oscData.clipAt(i + 1).at(0);
		nextTime !? { (nextTime - time).wait };
	};
	"---- finished.".postln;
}
)

