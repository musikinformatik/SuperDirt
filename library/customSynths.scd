(
// Retrieved from http:sccode.org/1-5aD
// DrumSynths SC Example — SOS Drums by Renick Bell, renick_at_gmail.com
// recipes from Gordon Reid in his Sound on Sound articles
// SOSsnare — http:www.soundonsound.com/sos/Mar02/articles/synthsecrets0302.asp
// Latch.ar(WhiteNoise.ar(0.1), Impulse.ar(nyquist * 2)) is added aliasing for effect
// Modified by Bruno Ruviaro and Josh Mitchell 8/19.
// Adapted to SuperDirt by Aleksandr Yakunichev, hi@ya.codes
//
// voice - controls modulation input phase in radians (min: 0, max: your sanity)
// semitone - modulation frequency in semitones of fundamental
// pitch1 - resonance filter frequency (Hz)
// resonance - resonance of bandpass and resonz filters (min: 0, max: 1)
SynthDef(\testSynth , {
  arg out, pan, freq = 405, voice = 0.385, semitone = 0.452, pitch1 = 2000, resonance = 0.1, sustain = 0.5;
  var source, noise, envelope;

  source = PMOsc.ar(Saw.ar(freq * 0.85), freq * semitone, voice);

  noise = Latch.ar(WhiteNoise.ar(0.1), Impulse.ar(1700 * 2));
  noise = BRF.ar(noise, 4 * pitch1, resonance, 0.5);
  noise = BRF.ar(noise, 2.5 * pitch1, resonance, 0.5);
  noise = BRF.ar(noise, 1.8 * pitch1, resonance, 0.5);
  noise = BRF.ar(noise, pitch1, resonance, Env.perc(0.005, sustain, -4).ar);
  noise = Resonz.ar(noise, pitch1, 1, 40);

  envelope = Env.perc(0.005, sustain, 0.5, -4).ar(Done.freeSelf);

  OffsetOut.ar(out, DirtPan.ar((source + noise) * 4.dbamp, ~dirt.numChannels, pan, envelope));
},
metadata: (
  credit: "Renick Bell",
  category: \drums,
  tags: [\pitched, \snare, \sos]
)).add;
);
