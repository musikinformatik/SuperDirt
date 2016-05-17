+ SuperDirt {


	// convenient startup method
	*start { |numChannels = 2, server, numOrbits = 2, port = 57120, senderAddr|
		server = server ? Server.default;
		server.options.numBuffers = 1024 * 16; // increase this if you need to load more samples
		server.options.memSize = 8192 * 16; // increase this if you get "alloc failed" messages
		server.options.maxNodes = 1024 * 32; // increase this if you are getting drop outs and the message "too many nodes"
		// boot the server and start SuperDirt
		server.waitForBoot {
			~dirt = SuperDirt(numChannels, server); // two output channels, increase if you want to pan across more channels
			~dirt.loadSoundFiles;   // load samples (path can be passed in)
			server.sync; // wait for samples to be read
			~dirt.start(port, 0 ! numOrbits, senderAddr);   // start listening on port 57120, create two busses each sending audio to channel 0
		};

		server.latency = 0.3; // increase this if you get "late" messages
	}

}

