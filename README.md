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
Quarks.install("https://github.com/musikinformatik/SuperDirt.git");
Quarks.install("Vowel");
```

## Setup
```
(
// configure the sound server: here you could add hardware specific options
// see http://doc.sccode.org/Classes/ServerOptions.html
s.options.numBuffers = 1024 * 16;
s.options.memSize = 8192 * 16;
// boot the server and start SuperDirt
s.waitForBoot {
	~dirt = SuperDirt(2, s); // two output channels
	~dirt.loadSynthDefs; 	// load user defined synthdefs (path can be passed)
	~dirt.loadSoundFiles;	// load samples (path can be passed) mono is assumed.
	s.sync; // wait for samples
	~dirt.start([57120, 57121]);		// start listening on port 57120
}
)
// now you should be able to send from tidal via port 57120 and 57212
```

## Setup from Tidal
```
d1 <- stream "127.0.0.1" 57120 dirt {timestamp = BundleStamp}
d2 <- stream "127.0.0.1" 57121 dirt {timestamp = BundleStamp}
```
Now you can run a pattern, e.g.
```
d1 $ sound "bd [cy:1 cy:2] bd"
```

##Options on startup
- numChannels can be set to anything your soundcard supports
- you can pass the udp port on which superdirt is listenting (```.start(ports, channels)```)
- you can edit the SynthDef file to add your own synthesis methods to be called from tidal: https://github.com/telephon/SuperDirt/blob/master/synths/default-synths.scd
- for server options, see ServerOptions helpfile
