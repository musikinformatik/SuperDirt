
/*

these function as effects on the input of the synth or sample (see SynthDefs in core-synths)
they respond to the existence of a value for one of the tidal parameters

// "to" is an internal superdirt audio routing bus index. So you play audio to this bus.

(C) 2015-2020 Julian Rohrhuber and contributors
SuperDirt is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 2 of the License, or (at your
option) any later version.

*/


~dirt.addModule('out_to',
	{ |dirtEvent|
		var busses = ~dirt.audioRoutingBusses;
		var bus = busses.wrapAt(~to.asInteger);
		dirtEvent.sendSynth("dirt_out" ++ ~numChannels,
			[
				to: bus.index,
				out: ~out
			]
		)
}, { ~to.notNil });



// # from 3 # toArg "freq"
// from are the superdirt internal audio routing busses
// synth needs to have an audio rate control.
// it would be nice to be able to map several arguments

~dirt.addModule('map_from',
	{ |dirtEvent|
		var busses = ~dirt.audioRoutingBusses;
		var bus = if(~from.isNil) { busses.at(0) } { busses.wrapAt(~from.asInteger) };
		~server.sendMsg(
			"/n_mapan",
			~synthGroup,
			~toArg,
			bus.index,
			~dirt.numChannels
		)
}, { ~toArg.notNil });

