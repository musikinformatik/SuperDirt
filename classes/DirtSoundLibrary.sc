
/*

This library unifies access to buffers and synth events.
It mainly keeps a link back to dirt for the server and to generate the instrument name for a given number of channels

*/


DirtSoundLibrary {

	var <dirt, <buffers, <bufferEvents, <synthEvents;
	var <>fileExtensions = #["wav", "aif", "aiff", "aifc"];

	*new { |dirt|
		^super.newCopyArgs(dirt).init
	}

	init {
		if(buffers.notNil) { this.freeAllSoundFiles };
		buffers = IdentityDictionary.new;
		bufferEvents = IdentityDictionary.new;
		synthEvents = IdentityDictionary.new;
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
		synthEvents[name] = synthEvents[name].add(event);
	}

	getEvent { |name, index|
		// first look up buffers, then synths
		var allEvents = bufferEvents[name] ?? { synthEvents[name] };
		if(allEvents.isNil) {
			^if(SynthDescLib.at(name).notNil) {
				(instrument: name)
				//sustainControl =  synthDesc.controlDict.at(\sustain);
				//if(sustainControl.notNil) { ~delta = sustainControl.defaultValue }
			}
		};
		^allEvents.wrapAt(index.asInteger)
	}

	set { |name, indices ... pairs|
		var allEvents = bufferEvents[name] ?? { synthEvents[name] };
		if(allEvents.isNil) {
			"set: no events found with this name: %\n".format(name).warn
		} {
			if(indices.notNil) { allEvents = allEvents.at(indices.asArray) };
			allEvents.do { |each|
				each.putPairs(pairs)
			}
		}
	}

	makeEventForBuffer { |buffer|
		^(
			buffer: buffer.bufnum,
			instrument: format("dirt_sample_%_%", buffer.numChannels, dirt.numChannels).asSymbol,
			unitDuration: buffer.duration
		)
	}


	/*

	File loading

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

		if(dirt.server.serverRunning.not) { "Superdirt: server not running - cannot load sound files.".throw };

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
		if(dirt.server.serverRunning.not) { "Superdirt: server not running - cannot load sound files.".throw };
		fileExt = (path.splitext[1] ? "").toLower;
		if(fileExtensions.includesEqual(fileExt)) {
			buf = Buffer.readWithInfo(dirt.server, path);
			if(buf.isNil) {
				"\n".post; "File reading failed for path: '%'\n\n".format(path).warn
			} {
				this.addBuffer(name, buf, appendToExisting)
			}
		} {
			if(dirt.verbose) { "\nignored file: %\n".postf(path) };
		}
	}

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

	freeSoundFiles { |names|
		names.do { |name|
			buffers.removeAt(name).asArray.do { |buf|
				if(this.findBuffer(buf).notNil) { buf.free } // don't free aliases
			};
			bufferEvents.removeAt(name);
		}
	}

	freeSynths { |names|
		names.do { |name|
			synthEvents.removeAt(name)
		}
	}

	freeAllSoundFiles {
		buffers.do { |x| x.asArray.do { |buf| buf.free } };
		buffers = ();
		bufferEvents = ();
	}

	findBuffer { |buf|
		buffers.keysValuesDo { |key, val|
			var index = val.indexOf(buf);
			if(index.notNil) { ^[key, index] };
		};
		^nil
	}



}