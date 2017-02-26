
// cycle test
(
~dirt.receiveAction = { |e|
	var cycle = e[\cycle];
	cycle !? {
		TempoClock.default.beats = cycle
	}
}
);

