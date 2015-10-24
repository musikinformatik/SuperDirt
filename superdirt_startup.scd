/*
This is an example startup file. You can load it from your startup file
(to be found in Platform.userAppSupportDir +/+ "startup.scd")
*/


(
// configure the sound server: here you could add hardware specific options
// see http://doc.sccode.org/Classes/ServerOptions.html
s.options.numBuffers = 1024 * 16; // increase this if you need to load more samples
s.options.memSize = 8192 * 16; // increase this if you get "alloc failed" messages
s.options.maxNodes = 1024 * 32; // increase this if you are getting drop outs and the message "too many nodes"
// boot the server and start SuperDirt
s.waitForBoot {
	~dirt = SuperDirt(2, s); // two output channels, increase if you want to pan across more channels
	~dirt.loadSoundFiles;   // load samples (path can be passed in)
	s.sync; // wait for samples to be read
	~dirt.start([57120, 57121]);   // start listening on port 57120 and 57121. Add more ports as needed.

	// optional, needed for the sclang tests only:
	(

		~d1 = ~dirt.dirtBusses[0]; // one port
		~d2 = ~dirt.dirtBusses[1]; // the other

	);
};

s.latency = 0.3; // increase this if you get "late" messages
);


