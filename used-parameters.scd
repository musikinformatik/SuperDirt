/*

a list of parameters with special use

*** These parameter names can change in the future. ***

You can use those parameters in your SynthDefs, but it’s good to know what they do. There is no documentation, but the information is in:

effects: `synths/core-modules.scd` and `synths/core-synths.scd`,
global effects: DirtOrbit
core: DirtEvent


Like in sclang in general, sustain parameter is the total duration of a sound (not just a sustain portion of an envelope)

*/


// core, sent from tidal
// they have specific meaning
// you can use these in your synthdefs directly if necessary
s
n
sound
begin
end
length
accelerate
cps
unit
loop
delta
legato
sustain
amp
gain
channel
pan
note
freq
midinote
octave
latency
lag
offset
cut
orbit
cycle

// core, dirt public
// you should use this in your synthdefs
out

// core, dirt internal
// they have specific meaning
// you shouldn't use these in your synthdefs
instrument
unitDuration
buffer
fadeTime
fadeInTime
endSpeed
synthGroup
dryBus
effectBus
numChannels
server
dirtOut
i_out


// used in effect modules
// you can use these in your synthdefs directly if necessary,
// but remember they are also triggering effect synths

shape
hcutoff
hresonance
bandf
bandq
crush
coarse
cutoff
attack
release
hold
tremolorate
tremolodepth
phaserrate
phaserdepth

// used in effect modules (private, don't use)
vowel


// used in global effects
// they have specific meaning
// you can use these in your synthdefs directly if necessary,
// but remember they are also triggering effect synths
delaytime
delayfeedback
delayAmp
lock
cps
size
room
dry
leslie
lrate
lsize


