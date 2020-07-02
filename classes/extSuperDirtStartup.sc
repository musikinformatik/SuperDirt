/*
(C) 2015-2020 Julian Rohrhuber and contributors
SuperDirt is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 2 of the License, or (at your
option) any later version.
*/

+ SuperDirt {


	// convenient startup method
	// two output channels, increase if you want to pan across more channels
	// start listening on port 57120, create two orbits each sending audio to channel 0

	*start { |numChannels = 2, server, numOrbits = 12, port = 57120, senderAddr, path|
		~dirt.free;
		server = server ? Server.default;
		server.options.numBuffers = 1024 * 256;
		server.options.memSize = 8192 * 16;
		server.options.maxNodes = 1024 * 32;
		// boot the server and start SuperDirt
		server.waitForBoot {
			~dirt = SuperDirt(numChannels, server);
			~dirt.loadSoundFiles(path);   // load samples (path can be passed in)
			server.sync;
			~dirt.start(port, 0 ! numOrbits, senderAddr);
		};

		server.latency = 0.3;
	}

}

