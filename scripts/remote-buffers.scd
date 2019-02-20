/*

If you are playing with your own SuperDirt on a remote SuperDirt server,
you may want to get sound file information from the remote SuperDirt application,
which has loaded the buffers.

RemoteSoundfileInfo makes this easy.
It has to run on both sides of the network connection.

*/


~remote = DirtRemoteSoundfileInfo(~dirt.soundLibrary).start(57120);

// ~addr = NetAddr("a.b.c.d", 57120); // on the requester side: replace "a.b.c.d" with the remote address

// testing with loopback
~addr = NetAddr("127.0.0.1", 57120);

// just posting them:
~remote.sendRequest(~addr, { |buffers| buffers.postln });

// adding them to the library of a second instance of a library:

~lib = DirtSoundLibrary(s, 2); // make a fresh one for testing
// ~lib = ~dirt.soundLibrary; // this would be the one you'd use if you want to load into your current dirt
~lib.freeAllSoundFiles;  // but better free the old ones. comment out if you know what you are doing ...

(
~remote.sendRequest(~addr, { |buffers|
	 // they come in key value pairs
	buffers.pairsDo { |key, buffer|
		[key, buffer].postln;
		~lib.addBuffer(key, buffer, appendToExisting: true)
	}
})
)

~lib.bufferEvents.keys
~lib.bufferEvents


