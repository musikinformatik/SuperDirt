# SuperDirt 0.1
SuperCollider implementation of the Dirt sampler for the Tidal programming language

Alex McLean and Julian Rohrhuber

This is still experimental.

## Requirements

* SuperCollider > v3.7: https://github.com/supercollider/supercollider
* The Vowel Quark: https://github.com/supercollider-quarks/Vowel
* For proper usage you need https://github.com/tidalcycles/Tidal

## Installation from SuperCollider
```
Quarks.install("https://github.com/musikinformatik/SuperDirt.git")
```

## Setup
```
(
s.options.numBuffers = 1024 * 16;
s.options.memSize = 8192 * 16;
s.waitForBoot {
	~dirt = SuperDirt(2, s); // two output channels
	~dirt.loadSynthDefs; 	// load user defined synthdefs
	~dirt.loadSoundFiles;	// load samples (path can be passed) mono is assumed.
	~dirt.start;		// start listening
}
)
// now you should be able to send from tidal via port 57120
```

##Options on startup
- numChannels can be set to anything your soundcard supports
- you can pass the udp port on which superdirt is listenting: ```SuperDirt(2, s, (port: 60777));```
- you can edit the SynthDef file to add your own synthesis methods to be called from tidal: https://github.com/telephon/SuperDirt/blob/master/synths/default-synths.scd


