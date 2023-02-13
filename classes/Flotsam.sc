/*

This kind of object drifts amoung the orbits.
SuperDirt makes them to track synths that are in a cut group

*/


Flotsam {
	var <nodeID, <cutGroup, <orbit, <hash;


	*new { |nodeID, cutGroup, orbit, hash|
		^super.newCopyArgs(nodeID, cutGroup, orbit, hash)
	}

}

