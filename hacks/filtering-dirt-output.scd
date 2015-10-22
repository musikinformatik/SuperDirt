

/*

how to route Dirt audio into post-processing in SuperCollider

This assumes that you have SuperDirt running and accesible in ~dirt

*/


// define a bus you'll be using for routing

~bus = Bus.audio(s, numChannels:2); // assuming stereo, expand if needed

~d1.outBus = ~bus; // play into that bus.


/*
Now, playing patterns in d1 in tidal should be silent.
*/

// listen directly
(
Ndef(\x, {
	var dirt = InBus.ar(~bus, 2);
	dirt
}).play;

)

// resonant low pass filter controlled by cursor
(
Ndef(\x, {
	var dirt = InBus.ar(~bus, 2);
	RLPF.ar(dirt, MouseY.kr(30, 20000, 1), MouseX.kr(0.01, 1, 1))
}).play;
)

// ... and so on.


/*
cleaning up when you're done:
*/

~d1.outBus = 0;
~bus.free;