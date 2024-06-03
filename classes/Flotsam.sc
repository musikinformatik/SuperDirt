/*

This kind of object drifts amoungst the orbits.
SuperDirt makes them to track synths that are in a cut group

*/


Flotsam {
	var <nodeID, <cutGroup, <orbit, <hash, <timeStamp;


	*new { |nodeID, cutGroup, orbit, hash, timeStamp|
		^super.newCopyArgs(nodeID, cutGroup, orbit, hash, timeStamp)
	}

}

