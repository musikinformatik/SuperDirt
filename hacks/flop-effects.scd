


// local to a synth
// try with tidal e.g.
// d1 $ s "gabor*4" # n "0 1 2 3"

~dirt.soundLibrary.putSynth(\gabor, (instrument: \gabor));
~dirt.soundLibrary.putSynth(\gabor, (instrument: \gabor, tremolodepth: 0.4, tremolorate: [212, 128]));
~dirt.soundLibrary.putSynth(\gabor, (instrument: \gabor, tremolodepth: 0.4, tremolorate: { [212, 128] + 130.0.rand2}));
~dirt.soundLibrary.putSynth(\gabor, (instrument: \gabor, tremolodepth: 0.4, tremolorate: Ndef(\x)));
Ndef(\x, {[ MouseX.kr(100, 1000, 1), MouseY.kr(100, 1000, 1)] });



// global on an orbit:
// try with tidal
// d1  $ s "hh*12" # n "0 1 2 3"

~dirt.orbits[0].set(\bandf, [11300, 1700, 2000], \bandq, 18.9);

Ndef(\x, {[ MouseX.kr(100, 1000, 1), MouseY.kr(100, 1000, 1)] });
~dirt.orbits[0].set(\bandf, Ndef(\x), \bandq, 28.9);


Ndef(\y, { { LFNoise2.kr(1).exprange(200, 10000) } ! 8 }); // eight filters.
~dirt.orbits[0].set(\bandf, Ndef(\y), \bandq, 28.9);

// reset
~dirt.orbits[0].set(\bandf, nil, \bandq, nil);
