+ Buffer {

	/*
	This guarantees that buffer info exists before the buffer is on the server.
	*/

	*readWithInfo { |server, path, startFrame = 0, numFrames = -1|
		var buffer = this.new(server), failed;
		SoundFile.use(path, { |file|
			buffer.sampleRate = file.sampleRate;
			buffer.numFrames = file.numFrames;
			buffer.numChannels = file.numChannels;
		});
		failed = buffer.numFrames == 0;
		^if(failed) {
			buffer.free; // free buffer number
			nil
		} {
			buffer.allocRead(path, startFrame, numFrames)
		}
	}

	// in bytes
	memoryFootprint {
		^numFrames * numChannels * 4
	}

}
