/*

How to add new effects to Tidal and SuperDirt.

This is a three step process.

1. add the desired parameters to Tidal, so it can be used
2. add a module definition to Superdirt, so it can be found when the parameter is not nil
3. add the synth def to SuperDirt, so it can be played


The following example adds a spectral delay, called "sdelay"

*/


// (1) add this to  Sound/Tidal/Params.hs

sdelay :: Pattern Int -> ParamPattern
sdelay = make' VF sdelay_p
sdelay_p = F "sdelay" Nothing


// (2) add module that responds
(
~dirt.addModule('spectral-delay',
	{ |dirtEvent|
		dirtEvent.sendSynth("sdelay" ++ ~numChannels,
			[
				delay: ~sdelay,
				out: ~out
		])

}, { ~sdelay.notNil });
)


// (3) make a bunch of synthdefs (for each possible channel size one)

