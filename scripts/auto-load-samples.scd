/*

If you have limited RAM, you may not want to preload all samples.
Then you can use this script to dynamically try and load them.

*/


(
// keep track of what we have tried to load
var failed = Set.new;

// try to laod
var autoLoad = { |sound|
	if(failed.includes(sound).not) {
		failed.add(sound);
		~dirt.loadOnly([sound]);
		if(~dirt.buffers.at(sound).notNil) { failed.remove(sound) };
	} {
		// if loading fails, here is a message:
		"couldn't load soundfile for %\n".format(sound).postln
	}
};

// use the "\notFound" hook in dirt.
~dirt.set(\notFound, { autoLoad.(~s) });
)


// try it out: while playing any tidal pattern, now remove all samples:

~dirt.freeSoundFiles

// they should automatically come back.