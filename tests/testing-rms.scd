


(
var w, levels;
w = Window("levels", Rect(100, 100, 500, 400)).front;
~dirt.startSendRMS;
levels = ~dirt.orbits.collect { |orbit, i|
	orbit.defaultParentEvent.put(\rmsReplyRate, 8).put(\rmsPeakLag, 3);
	LevelIndicator(w, Rect(21 * i + 10, 10, 20, 180) ).warning_(0.9).critical_(1.0)
};

OSCFunc({ |msg|
	defer {
		var a = levels[msg[2]];
		a.value = msg[3].ampdb.linlin(-40, 0, 0, 1);
		a.peakLevel = msg[4].ampdb.linlin(-40, 0, 0, 1);
	}

}, "/rms");
CmdPeriod.doOnce { w.close };
)


// to stop it
~dirt.stopSendRMS;