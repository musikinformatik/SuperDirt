

// allow a maximum of four seconds, adjust to your needs: this represents one tidal cycle
// we need two of them.
~recBufs = { Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * 4, ~dirt.numChannels) } ! 2;


(
var functions = ();  // make a dictionary of functions
var recSynth, counter = 0, recording = false;
var path = "~/tidalchunks/";
var whichOrbit = ~dirt.orbits[0];

if(pathMatch(path +/+ "*").isEmpty) { unixCmd("mkdir" + path) };


SynthDef(\record, { |bufnum|
	var in = InFeedback.ar(whichOrbit.outBus, ~dirt.numChannels);
	RecordBuf.ar(in, bufnum, loop:0, doneAction:2);
}).add;


functions[\startRec] = {
	if(recording) { functions[\stopRec].value };
	counter = counter + 1;
	recSynth = Synth(\record, ~recBufs @@ counter);
	recording = true;
};

functions[\stopRec] = {
	if(recording) {
		(~recBufs @@ counter).write(path +/+ "chunk" ++ counter ++ ".aiff");
		recSynth.free;
		recording = false;
	}
};

// use the "diversion" key as a hook for playing the synth
~d1.defaultParentEvent[\diversion] = {
	var div = functions[~s];
	if(div.notNil) { div.value; 1.0 }
};
)
