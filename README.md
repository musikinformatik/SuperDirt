# SuperDirt 1.0-dev
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

For an example startup file, see the file `superdirt_startup.scd`. you can `load(<path>)` this from the SuperCollider startup file.

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
It is in principle possible to use SuperCollider 3.6, but startup will be much slower by comparison. It is **not** recommended if you expect it to run smoothly.

For reference, we leave here the instructions if you want to try anyway:

The install works differently: don't do `include("SuperDirt")`, but instead download the three quarks to the SuperCollider `Extensions` folder:
- https://github.com/musikinformatik/SuperDirt
- https://github.com/tidalcycles/Dirt-Samples
- https://github.com/supercollider-quarks/Vowel

Note that for automatically loading the sound files, the folder `Dirt-Samples` should have this name (not Dirt-Samples-master e.g.) and should be next to the SuperDirt folder.
