
// live spatialisation over many channels / multichannel routing across non-adjacent channels


// getting tidal output into node proxies

Ndef(\dirty).ar(~dirt.numChannels); // make a place for a signal
~dirt.orbits.do { |each| each.outBus = Ndef(\dirty).bus };

// to see what you are doing, you can open a scope for the outputs:
s.scope(12);


/* route stereo input channels to output:

0 -> 0 (amp: 1)
1 -> 6 (amp: 0.5)
0 -> 8 (amp: 0.7)

*/

Ndef(\dirty).playN([0, 6, 8], [1, 0.5, 0.7], [0, 1, 0]); // outs, amps, ins

/* change them on the fly

0 -> 0 (amp: 1)
1 -> 6 (amp: 0.5)
0 -> 8 (amp: 0.7)

*/

Ndef(\dirty).playN([0, 7, 3], [0.6, 0.5, 0.7], [0, 1, 1]);


// you can specify a fadeTime to crossfade different settings
// e.g.

Ndef(\dirty).playN([1, 2, 4], [1, 0.5, 0.7], [0, 1, 0], fadeTime: 4);

// for more informations, see playN helpfile


// for using tidal for controlling the channel distribution
// best a multichannel SuperDirt:

// simple 8-channel setup, synths only
(
~dirt = SuperDirt(8, s);
~dirt.start(57120, 0 ! 4);
SuperDirt.default = ~dirt;
)

// same as above
(
Ndef(\dirty).ar(~dirt.numChannels); // make a place for a signal
~dirt.orbits.do { |each| each.outBus = Ndef(\dirty).bus };
Ndef(\dirty).scope;

Ndef(\dirty).play(0, 2); // this assumes that you have a stereo system. use playN as above for multichannel routing.
)

// now you can use # channel in tidal to send to different channels.
// simulate in sclang:

(
fork {
	16.do { |i|
		(type:\dirt,  s:\imp, channel:i, sustain: 1.3, freq: 200 + (i * 20), pan:-1).play;
		0.2.wait
	}
}
)




