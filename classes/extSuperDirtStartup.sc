+ SuperDirt {


	// convenient startup method
	// two output channels, increase if you want to pan across more channels
	// start listening on port 57120, create two orbits each sending audio to channel 0

	*start { |numChannels = 2, server, numOrbits = 2, port = 57120, senderAddr, path|
		~dirt.free;
		server = server ? Server.default;
		server.options.numBuffers = 1024 * 16;
		server.options.memSize = 8192 * 16;
		server.options.maxNodes = 1024 * 32;
		// boot the server and start SuperDirt
		server.waitForBoot {
			~dirt = SuperDirt(numChannels, server);
			"loading default samples".postln;
			~dirt.loadSoundFiles; // load default samples
			// now load any other samples (path can be passed in)
			if (path.notNil, { "loading samples from supplied path".postln; ~dirt.loadSoundFiles(path); }, { "no path supplied, not loading any other samples".postln });
			server.sync;
			~dirt.start(port, 0 ! numOrbits, senderAddr);
		};

		server.latency = 0.3;
	}

}
