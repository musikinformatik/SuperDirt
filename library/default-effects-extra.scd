// Waveloss
// Divides an audio stream into tiny segments, using the signal's
// zero-crossings as segment boundaries, and discards a fraction of them.

(
SynthDef("waveloss" ++ ~dirt.numChannels, { |out, drop = 1|
  var sig;

  sig = In.ar(out, ~dirt.numChannels);
  sig = WaveLoss.ar(sig, drop, outof: 100, mode: 2);
  ReplaceOut.ar(out, sig)
}).add;

~dirt.addModule('waveloss', { |dirtEvent|
  dirtEvent.sendSynth('waveloss' ++ ~dirt.numChannels,
    [
      drop: ~waveloss,
      out: ~out
    ]
  )
}, { true });

// Squiz
// "reminiscent of some weird mixture of filter, ring-modulator
// and pitch-shifter"

SynthDef("squiz" ++ ~dirt.numChannels, { |out, pitchratio = 1|
  var sig;
  sig = In.ar(out, ~dirt.numChannels);
  sig = Squiz.ar(sig, pitchratio);
  ReplaceOut.ar(out, sig)
}).add;

~dirt.addModule('squiz', { |dirtEvent|
  dirtEvent.sendSynth('squiz' ++ ~dirt.numChannels,
    [
      pitchratio: ~squiz,
      out: ~out
    ]
  )
}, { true });
)
