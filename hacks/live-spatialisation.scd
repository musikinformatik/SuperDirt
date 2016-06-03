
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

Ndef(\dirty).playN([0, 6, 8], [1, 0.5, 0.7], [0, 1, 0]);

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