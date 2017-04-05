
// this allows you to record the data sent from tidal and mess with it from sclang
// right now, there is some detail missing, the result is not exact

(
~recordingRunning = false;
~initRecording = {
	~recording = List.new;

	~dirt.receiveAction = { |event|
		var e = event.copy;
		if(~recordingRunning) {
			e.use {
				~type = \dirt;
				~dur = ~delta;
			};
			~recording.add(e)
		}
	};
};

~startRecording = {
	~recordingRunning = true;
};

~normalizeLatencies = { |list|
	var min = 0;
	if(list.notEmpty) {
		list.do { |event| min = min(min, event[\latency]) };
		min = max(min, s.latency);
		[\minLatency, min].postln;
		list.do { |event| event[\latency] = event[\latency] - min };
	};
	list
};
~stopRecording = {
	~recordingRunning = false;
	~normalizeLatencies.(~recording)
};
)

~initRecording.value;
~startRecording.value;
~stopRecording.value;

SuperDirt.default = ~dirt;

// play it back
Pdef(\x, Pseq(~recording)).play;
Pdef(\x, Pseq(~recording, inf)).play; // looped


// mess with it
Pdef(\x, Pdict(~recording, Pseq([0, 4, 5] + 100, inf)  % ~recording.size)).play;
Pdef(\x, Pdict(~recording, Pseq((0..50) + 7, inf) % ~recording.size, default:Event.silent(0.01))).play;
Pdef(\x, Pdict(~recording, Pseq((0..50).curdle(0.3).scramble.flat + 7, inf) % ~recording.size, default:Event.silent(0.01))).play;


// while running, you can continue to send stuff from tidal:

~startRecording.value;

~stopRecording.value;


// clean up:

~dirt.receiveAction = nil;
