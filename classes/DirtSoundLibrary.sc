
/*

This library unifies access to buffers and synth events.

valid fileExtensions can be extended, currently they are ["wav", "aif", "aiff", "aifc"]

*/


DirtSoundLibrary {

	var <server, <numChannels, <buffers, <bufferEvents, <synthEvents;
	var <>fileExtensions = #["wav", "aif", "aiff", "aifc"];
	var <>verbose = false;

	*new { |server, numChannels|
		^super.newCopyArgs(server, numChannels).init
	}

	init {
		buffers = IdentityDictionary.new;
		bufferEvents = IdentityDictionary.new;
		synthEvents = IdentityDictionary.new;
	}

	free {
		synthEvents.clear;
		this.freeAllSoundFiles;
	}

	addBuffer { |name, buffer, appendToExisting = true|
		if(buffer.isNil) { Error("tried to add Nil to buffer library").throw };
		if(synthEvents[name].notNil) {
			"a synth event with that name already exists: %\nSkipping...".format(name).warn;
			^this
		};
		name = name.asSymbol;
		if(appendToExisting.not and: { buffers[name].notNil }) {
			"\nreplacing '%' (%)\n".postf(name, buffers[name].size);
			this.freeSoundFiles(name);
		};
		buffers[name] = buffers[name].add(buffer);
		bufferEvents[name] = bufferEvents[name].add(this.makeEventForBuffer(buffer));
	}

	addSynth { |name, event, appendToExisting = true|
		if(event.isNil) { Error("tried to add Nil to synth event library").throw };
		if(bufferEvents[name].notNil) {
			"a sample buffer with that name already exists: %\nSkipping...".format(name).warn;
			^this
		};
		if(appendToExisting.not and: { synthEvents[name].notNil }) {
			"\nreplacing '%' (%)\n".postf(name, synthEvents[name].size);
			synthEvents[name] = nil;
		};
		if(event[\hash].notNil) { event[\hash] = name.identityHash };
		synthEvents[name] = synthEvents[name].add(event);
	}

	freeSoundFiles { |names|
		names.asArray.do { |name|
			buffers.removeAt(name).asArray.do { |buf|
				if(this.findBuffer(buf).notNil) { buf.free } // don't free aliases
			};
			bufferEvents.removeAt(name);
		}
	}

	freeSynths { |names|
		names.asArray.do { |name|
			synthEvents.removeAt(name)
		}
	}

	set { |name, indices ... pairs|
		var allEvents = this.at(name);
		if(allEvents.isNil) {
			"set: no events found with this name: %\n".format(name).warn
		} {
			if(indices.notNil) { allEvents = allEvents.at(indices.asArray) };
			allEvents.do { |each|
				each.putPairs(pairs)
			}
		}
	}

	at { |name|
		^bufferEvents[name] ?? { synthEvents[name] }
	}


	freeAllSoundFiles {
		buffers.do { |x| x.asArray.do { |buf| buf.free } };
		buffers = IdentityDictionary.new;
		bufferEvents = IdentityDictionary.new;
	}



	/*

	file loading

	*/


	loadOnly { |names, path, appendToExisting = false|
		path = path ?? { "../../Dirt-Samples/".resolveRelative };
		names.do { |name|
			this.loadSoundFileFolder(path +/+ name, name, appendToExisting)
		};
		"\n... file reading complete\n\n".post;
	}

	loadSoundFiles { |paths, appendToExisting = false, namingFunction = (_.basename)|
		var folderPaths, memory;

		paths = paths ?? { "../../Dirt-Samples/*".resolveRelative };
		folderPaths = if(paths.isString) { paths.pathMatch } { paths.asArray };
		folderPaths = folderPaths.select(_.endsWith(Platform.pathSeparator.asString));
		if(folderPaths.isEmpty) {
			"no folders found in paths: '%'".format(paths).warn; ^this
		};
		memory = this.memoryFootprint;
		"\nloading % sample bank%:\n".postf(folderPaths.size, if(folderPaths.size > 1) { "s" } { "" });
		folderPaths.do { |folderPath|
			this.loadSoundFileFolder(folderPath, namingFunction.(folderPath), appendToExisting)
		};
		"\n... file reading complete. Required % MB of memory.\n\n".format(this.memoryFootprint - memory div: 1e6).post;
	}

	loadSoundFileFolder { |folderPath, name, appendToExisting = false|
		var files;
		if(File.exists(folderPath).not) {
			"\ncouldn't load '%' files, path doesn't exist: %.".format(name, folderPath).postln; ^this
		};
		files = (folderPath.standardizePath +/+ "*").pathMatch;
		name = name.asSymbol;

		if(server.serverRunning.not) { "Superdirt: server not running - cannot load sound files.".throw };

		if(appendToExisting.not and: { buffers[name].notNil } and: { files.notEmpty }) {
			"\nreplacing '%' (%)\n".postf(name, buffers[name].size);
			this.freeSoundFiles(name);
		};

		files.do { |filepath|
			this.loadSoundFile(filepath, name, true)
		};

		if(files.notEmpty) {
			"% (%) ".postf(name, buffers[name].size)
		} {
			"empty sample folder: %\n".postf(folderPath)
		};
	}

	loadSoundFile { |path, name, appendToExisting = false|
		var buf, fileExt;
		if(server.serverRunning.not) { "Superdirt: server not running - cannot load sound files.".throw };
		fileExt = (path.splitext[1] ? "").toLower;
		if(fileExtensions.includesEqual(fileExt)) {
			buf = Buffer.readWithInfo(server, path);
			if(buf.isNil) {
				"\n".post; "File reading failed for path: '%'\n\n".format(path).warn
			} {
				this.addBuffer(name, buf, appendToExisting)
			}
		} {
			if(verbose) { "\nignored file: %\n".postf(path) };
		}
	}



	/* access */


	findBuffer { |buf|
		buffers.keysValuesDo { |key, val|
			var index = val.indexOf(buf);
			if(index.notNil) { ^[key, index] };
		};
		^nil
	}

	getEvent { |name, index|
		// first look up buffers, then synths
		var allEvents = this.at(name);
		^if(allEvents.isNil) {
			if(SynthDescLib.at(name).notNil) {
				(instrument: name, hash: name.identityHash)
				//sustainControl =  synthDesc.controlDict.at(\sustain);
				//if(sustainControl.notNil) { ~delta = sustainControl.defaultValue }
			}
		} {
			allEvents.wrapAt(index.asInteger)
		}
	}

	makeEventForBuffer { |buffer|
		^(
			buffer: buffer.bufnum,
			instrument: this.instrumentForBuffer(buffer),
			unitDuration: buffer.duration,
			hash: buffer.identityHash
		)
	}

	instrumentForBuffer { |buffer|
		^format("dirt_sample_%_%", buffer.numChannels, this.numChannels).asSymbol
	}

	openFolder { |name, index = 0|
		var buf, list;
		list = buffers.at(name);
		if(list.isNil) { "No buffer for this name: %".format(name).warn; ^this };
		buf = list.at(index);
		if(buf.isNil) { "No buffer at this index: %:%".format(name, index).warn; ^this };
		systemCmd("open" + buf.path.dirname)
	}

	/* copy  */

	shallowCopy {
		^super.shallowCopy.prCopyEvents
	}

	numChannels_ { |n|
		numChannels = n;
		bufferEvents = bufferEvents.collect { |list|
			list.do { |event|
				event[\instrument] = this.instrumentForBuffer(event[\buffer])
			}
		}
	}


	/* info */

	postSampleInfo {
		var keys = buffers.keys.asArray.sort;
		if(buffers.isEmpty) {
			"\nCurrently there are no samples loaded.".postln;
		} {
			"\nCurrently there are % sample banks in memory (% MB):\n\nName (number of variants), range of durations (memory)\n"
			.format(buffers.size, this.memoryFootprint div: 1e6).postln;
		};
		keys.do { |name|
			var all = buffers[name];
			"% (%)   % - % sec (% kB)\n".postf(
				name,
				buffers[name].size,
				all.minItem { |x| x.duration }.duration.round(0.01),
				all.maxItem { |x| x.duration }.duration.round(0.01),
				all.sum { |x| x.memoryFootprint } div: 1e3
			)
		}
	}

	memoryFootprint {
		^buffers.sum { |array| array.sum { |buffer| buffer.memoryFootprint.asFloat } } // in bytes
	}

	/* private implementation */

	prCopyEvents {
		bufferEvents = bufferEvents.copy;
		synthEvents = synthEvents.copy;
	}



}