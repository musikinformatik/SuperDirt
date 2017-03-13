


(
var functions = ();  // make a dictionary of functions
var recSynth, recBufs, counter = 0, recording = false;
var path = "~/tidalchunks/";
var whichOrbit = ~dirt.orbits[0];
var maxTime = 4; // allow a maximum of four seconds, adjust to your needs: this represents one tidal cycle

if(pathMatch(path +/+ "*").isEmpty) { unixCmd("mkdir" + path) };


~recBufs.do(_.free); // free them if they are left over (this is why we keep it in the environment variable)
// we need two buffers
~recBufs = recBufs = { Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * maxTime, ~dirt.numChannels) } ! 2;


SynthDef(\record, { |bufnum|
	var in = InFeedback.ar(whichOrbit.outBus, ~dirt.numChannels);
	RecordBuf.ar(in, bufnum, loop:0, doneAction:2);
}).add;


functions[\startRec] = {

	if(recording) { functions[\stopRec].value };
	counter = counter + 1;
	~server.makeBundle(~latency, {
		recSynth = Synth(\record, recBufs @@ counter, ~server);
		recording = true;
	})
};

functions[\stopRec] = {
	if(recording) {
		~server.makeBundle(~latency, {
			(recBufs @@ counter).write(path +/+ "chunk" ++ Date.localtime.stamp ++ ".aiff");
			recSynth.free;
			recording = false;
		})
	}
};

// use the "diversion" key as a hook for playing the synth
~dirt.orbits[0].defaultParentEvent[\diversion] = {
	var div = functions[~s];
	if(div.notNil) { div.value; 1.0 }
};



)


// open the directory with the sound files

systemCmd("open" + "~/tidalchunks/");

