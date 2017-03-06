# SuperDirt 0.9
SuperCollider implementation of the Dirt sampler for the Tidal programming language

Alex McLean and Julian Rohrhuber

## Requirements

* SuperCollider >= v3.7 (3.6 possible, but see below): https://github.com/supercollider/supercollider
* The Vowel Quark: https://github.com/supercollider-quarks/Vowel
* optional, but recommended: sc3-plugins: https://github.com/supercollider/sc3-plugins/
* For proper usage you need https://github.com/tidalcycles/Tidal

## Installation from SuperCollider
```
include("SuperDirt");
```
Note: this also automatically installs the DirtSamples quark, which contains a large collection of sound files. It downloads them as a zip file. Sometimes, git fails to unpack these samples and they don't get listed. In this case, you have to unpack them "manually".

## Simple Setup

`SuperDirt.start`

You can pass `port`, `outBusses`, `senderAddr` as arguments.

## Setup with options
```
(
// configure the sound server: here you could add hardware specific options
// see http://doc.sccode.org/Classes/ServerOptions.html
s.options.numBuffers = 1024 * 16; // increase this if you need to load more samples
s.options.memSize = 8192 * 16; // increase this if you get "alloc failed" messages
s.options.maxNodes = 1024 * 32; // increase this if you are getting drop outs and the message "too many nodes"
s.options.numOutputBusChannels = 2; // set this to your hardware output channel size, if necessary
s.options.numInputBusChannels = 2; // set this to your hardware input channel size, if necessary
// boot the server and start SuperDirt
s.waitForBoot {
	~dirt = SuperDirt(2, s); // two output channels, increase if you want to pan across more channels
	~dirt.loadSoundFiles;   // load samples (path containing a wildcard can be passed in)
	// for example: ~dirt.loadSoundFiles("/Users/myUserName/Dirt/samples/*");
	s.sync; // wait for samples to be read
	~dirt.start(57120, [0, 0]);   // start listening on port 57120, create two orbits, each sending audio to channel 0. You can direct sounds to the orbits from tidal e.g. by: `# orbit "0 1 1"
}
)
// now you should be able to send from tidal via port 57120
```

## Setup from Tidal
```
(cps, getNow) <- bpsUtils
(d1, t1) <- superDirtSetters getNow
(d2, t2) <- superDirtSetters getNow
```
Now you can run a pattern, e.g.
```
d1 $ sound "[bd bd bd, sn cp sn cp]"

d2 $ sound "[sn*2 imp bd*3]" |+| speed "1"
```

## Automatic startup
If you want SuperDirt to start automatically, you can load it from the startup file. To do this, open the sc startup file (```File>Open startup file```) and add: ```load("... path to your tidal startup file ...")```. This path you can get by dropping the file onto the text editor.


## Options on startup
- `numChannels` can be set to anything your soundcard supports
- for server options, see `ServerOptions` helpfile: http://doc.sccode.org/Classes/ServerOptions.html

## Options on-the-fly
- add sound files. `~dirt.loadSoundFiles("path/to/my/samples/*")` You can drag and drop folders into the editor and add a wildcard (*) after it.
- you can pass the udp port on which superdirt is listenting and the output channel offsets: `~dirt.start(port, channels)`
- new orbits can be created on the fly (e.g. `~dirt.makeBusses([0, 0, 0])`).
- add or edit SynthDef files to add your own synthesis methods to be called from tidal: https://github.com/musikinformatik/SuperDirt/blob/master/synths/default-synths.scd
- you can live rewrite the core synths (but take care not to break them ...): https://github.com/musikinformatik/SuperDirt/blob/master/synths/core-synths.scd


## Using SuperDirt with SuperCollider 3.6
It is possible to use SuperCollider 3.6, but startup will be much slower by comparison.

The install works differently: don't do `include("SuperDirt")`, but instead download the three quarks to the SuperCollider `Extensions` folder:
- https://github.com/musikinformatik/SuperDirt
- https://github.com/tidalcycles/Dirt-Samples
- https://github.com/supercollider-quarks/Vowel

Note that for automatically loading the sound files, the folder `Dirt-Samples` should have this name (not Dirt-Samples-master e.g.) and should be next to the SuperDirt folder.
