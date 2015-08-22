/*
This is an example startup file. You can load it from your startup file
(to be found in Platform.userAppSupportDir +/+ "startup.scd")
*/


(
// configure the sound server: here you could add hardware specific options
// see http://doc.sccode.org/Classes/ServerOptions.html
s.options.numBuffers = 1024 * 16;
s.options.memSize = 8192 * 16;
// boot the server and start SuperDirt
s.waitForBoot {
	~dirt = SuperDirt(2, s); // two output channels
	~dirt.loadSynthDefs;    // load user defined synthdefs (path can be passed as argument)
	~dirt.loadSoundFiles;   // load samples (path can be passed) mono is assumed.
	s.sync; // wait for samples
	~dirt.start([57120, 57121]);        // start listening on port 57120 and 57121

	// optional, needed for the sclang tests only:
	(

		~d1 = ~dirt.dirtBusses[0]; // one port
		~d2 = ~dirt.dirtBusses[1]; // the other

	);
}
);

// access separate dirt busses directly

