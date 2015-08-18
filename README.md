# SuperDirt 0.1
SuperCollider implementation of the Dirt sampler for the Tidal programming language

## Requirements

SuperCollider > v3.7

## Setup
```
(
s.options.numBuffers = 1024 * 16;
s.options.memSize = 8192 * 16;
s.waitForBoot {
	~dirt = SuperDirt(2, s);
	~dirt.loadSynthDefs;
	~dirt.loadSoundFiles;
	~dirt.start;
}
)
````
