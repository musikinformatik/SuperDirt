/*

(C) 2015-2020 Julian Rohrhuber and contributors
SuperDirt is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 2 of the License, or (at your
option) any later version.

*/

+ Buffer {

	/*
	This guarantees that buffer info exists before the buffer is on the server.
	*/

	*readWithInfo { |server, path, startFrame = 0, numFrames = -1|
		var buffer = this.new(server), failed;
		if(server.serverRunning.not) { "server not running - cannot load sound file.".postln; this.throw };
		SoundFile.use(path, { |file|
			buffer.sampleRate = file.sampleRate;
			buffer.numFrames = file.numFrames;
			buffer.numChannels = file.numChannels;
		});
		failed = buffer.numFrames == 0;
		^if(failed) {
			"\n".post; "File reading failed for path: '%'\n\n".format(path).warn;
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
