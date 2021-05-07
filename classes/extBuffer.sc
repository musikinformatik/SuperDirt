+ Buffer {

	/*
	This guarantees that buffer info exists before the buffer is on the server.
	*/

	*readWithInfo { |server, path, startFrame = 0, numFrames = -1, onlyHeader = false, onComplete|
		^this.new(server).path_(path).readWithInfo(startFrame, numFrames, onlyHeader, onComplete)
	}

	readWithInfo { |startFrame = 0, argNumFrames = -1, onlyHeader = false, onComplete|
		var failed;
		if(server.serverRunning.not) { "server not running - cannot load sound file.".postln; this.throw };
		SoundFile.use(path, { |file|
			sampleRate = file.sampleRate;
			numFrames = file.numFrames;
			numChannels = file.numChannels;
		});
		failed = numFrames == 0;
		if(failed) {
			"\n".post; "File reading failed for path: '%'\n\n".format(path).warn;
			this.free; // free buffer number
			nil
		} {
			if(onlyHeader.not) {
				if(argNumFrames > 0) { numFrames = argNumFrames };
				this.allocRead(path, startFrame, numFrames, completionMessage: { |b|
					onComplete.value(b)
				});

			}
		}
	}

	// in bytes
	memoryFootprint {
		^numFrames * numChannels * 4
	}

}
