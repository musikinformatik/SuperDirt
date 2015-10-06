/*
This is an example startup file. You can load it from your startup file
(to be found in Platform.userAppSupportDir +/+ "startup.scd")
*/


(
// configure the sound server: here you could add hardware specific options
// see http://doc.sccode.org/Classes/ServerOptions.html
s.options.numBuffers = 1024 * 16;
s.options.memSize = 8192 * 16;
s.quit;
// boot the server and start SuperDirt
s.waitForBoot {

	~dirt = SuperDirt(2, s); // two output channels
	~dirt.loadSoundFiles;   // load samples (path can be passed) mono is assumed.
	s.sync; // wait for samples
	~dirt.start([57120, 57121]);        // start listening on port 57120 and 57121

	/*
	// if you want nine instances like in dirt, just use instead:
	~dirt.start(57120 + (0..9);
	*/

	// optional, needed for the sclang tests only:
	(

		~d1 = ~dirt.dirtBusses[0]; // one port
		~d2 = ~dirt.dirtBusses[1]; // the other

	);
}
);

// access separate dirt busses directly

