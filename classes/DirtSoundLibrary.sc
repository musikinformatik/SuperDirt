
/*

This library unifies access to buffers and synth events.

valid fileExtensions can be extended, currently they are ["wav", "aif", "aiff", "aifc"]

*/


DirtSoundLibrary {

	var <server, <numChannels, <buffers, <bufferEvents, <synthEvents, <metaDataEvents;
	var <>fileExtensions = #["wav", "aif", "aiff", "aifc"];
	var <>verbose = false;
	var <>defaultEvent;
	var <>doNotReadYet = false;

	*new { |server, numChannels|
		^super.newCopyArgs(server, numChannels).init
	}

	init {
		buffers = IdentityDictionary.new;
		bufferEvents = IdentityDictionary.new;
		synthEvents = IdentityDictionary.new;
		metaDataEvents = IdentityDictionary.new;
	}

	free {
		synthEvents.clear;
		this.freeAllSoundFiles;
	}

	addBuffer { |name, buffer, appendToExisting = false, metaData|
		var event;
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
		event = this.makeEventForBuffer(buffer);
		buffers[name] = buffers[name].add(buffer);
		bufferEvents[name] = bufferEvents[name].add(event);
		metaData !? { metaDataEvents[name] = metaDataEvents[name].add(metaData) };
		if(verbose) { "new sample buffer named '%':\n%\n\n".postf(name, event) };
	}

	addSynth { |name, event, appendToExisting = false, useSynthDefSustain = false, metaData|
		if(bufferEvents[name].notNil) {
			"a sample buffer with that name already exists: %\nSkipping...".format(name).warn;
			^this
		};
		if(appendToExisting.not and: { synthEvents[name].notNil }) {
			"\nreplacing '%' (%)\n".postf(name, synthEvents[name].size);
			this.freeSynths(name);
		};
		if(event.isNil) { event = (instrument: name) };
		if(event[\hash].isNil) { event[\hash] = name.identityHash };
		if(useSynthDefSustain) { this.useSynthDefSustain(event) };
		synthEvents[name] = synthEvents[name].add(event);
		metaData !? { metaDataEvents[name] = metaDataEvents[name].add(metaData) };
		if(verbose) { "new synth named '%':\n%\n\n".postf(name, event) };
	}

	addMIDI { |name, device, event, appendToExisting = false, metaData|
		var midiEvent = DirtEventTypes.midiEvent.copy.put(\midiout, device);
		if(event.notNil) { midiEvent.putAll(event) };
		this.addSynth(name, midiEvent, appendToExisting, false, metaData)
	}

	useSynthDefSustain { |event|
		event.use {
			~unitDuration = {
				var synthDesc = SynthDescLib.at(~instrument.value);
				var sustainControl, unitDuration;
				if(synthDesc.notNil) {
					sustainControl = synthDesc.controlDict.at(\sustain);
					if(sustainControl.notNil) {
						sustainControl.defaultValue
					}
				}
			}
		}
	}

	freeSoundFiles { |names|
		names.asArray.do { |name|
			buffers.removeAt(name).asArray.do { |buf|
				if(this.findBuffer(buf).notNil) { buf.free } // don't free aliases
			};
			bufferEvents.removeAt(name);
			metaDataEvents.removeAt(name);
		}
	}

	freeSynths { |names|
		names.asArray.do { |name|
			synthEvents.removeAt(name);
			metaDataEvents.removeAt(name);
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
		if(doNotReadYet.not) {
			"\n... file reading complete\n\n".post
		};
	}

	loadSoundFiles { |paths, appendToExisting = false, namingFunction = (_.basename)| // paths are folderPaths
		var folderPaths, memory;

		paths = paths ?? { "../../Dirt-Samples/*".resolveRelative };
		folderPaths = if(paths.isString) { paths.pathMatch } { paths.asArray };
		folderPaths = folderPaths.select(_.endsWith(Platform.pathSeparator.asString));
		if(folderPaths.isEmpty) {
			"no folders found in paths: '%'".format(paths).warn; ^this
		};
		memory = this.memoryFootprint;
		"\n\n% existing sample bank%:\n".postf(folderPaths.size, if(folderPaths.size > 1) { "s" } { "" });
		folderPaths.do { |folderPath|
			this.loadSoundFileFolder(folderPath, namingFunction.(folderPath), appendToExisting)
		};
		if(doNotReadYet) {
			"\n ... sample banks registered, will read files as necessary".postln;
		} {
			"\n... file reading complete. Required % MB of memory.\n\n".format(
				this.memoryFootprint - memory div: 1e6
			).post
		};
	}

	loadSoundFileFolder { |folderPath, name, appendToExisting = false|
		var files;

		if(File.exists(folderPath).not) {
			"\ncouldn't read '%' files, path doesn't exist: %.".format(name, folderPath).postln;
			^this
		};

		files = pathMatch(folderPath.standardizePath +/+ "*"); // dependent on operating system

		if(files.notEmpty) {
			name = name.asSymbol;
			this.loadSoundFilePaths(files, name, appendToExisting);
			"% (%) ".postf(name, buffers[name].size);
		} {
			"empty sample folder: %\n".postf(folderPath)
		}

	}

	loadSoundFilePaths { |filePaths, name, appendToExisting = false|

		filePaths.do { |filepath|
			try { |erreur|
				var buf = this.readSoundFile(filepath);
				if(buf.notNil) {
					this.addBuffer(name, buf, appendToExisting);
					appendToExisting = true; // append all others
				};
				if(erreur.isException) { erreur.reportError };
			}
		}

	}

	loadSoundFile { |path, name, appendToExisting = false|
		var buf = this.readSoundFile(path);
		if(buf.notNil) { this.addBuffer(name, buf, appendToExisting) }
	}

	readSoundFile { |path|
		var fileExt = (path.splitext[1] ? "").toLower;
		if(fileExtensions.includesEqual(fileExt).not) {
			if(verbose) { "\nignored file: %\n".postf(path) };
			^nil
		}
		^Buffer.readWithInfo(server, path, onlyHeader: doNotReadYet)
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

		var allEvents = this.at(name);
		var event;

		if(allEvents.isNil) {
			// first look up buffers, then synths
			event = if(SynthDescLib.at(name).notNil) {
				// use tidal's "n" as note, only for synths that have no event defined
				(instrument: name, hash: name.identityHash)
			} {
				if(defaultEvent.notNil) {
					(instrument: name, hash: name.identityHash).putAll(defaultEvent)
				}
			};

			^event

		} {
			// the index may be \none (a Symbol), but this converts it to 0
			event = allEvents.wrapAt(index.asInteger);
		};

		if(doNotReadYet and: { event.notNil and: { event[\notYetRead] ? false } }) {
			"reading soundfile as needed: %:%".format(name, index).postln;
			this.readFileIfNecessary(event);
			if(server.hasBooted.not) { ^nil }; //  avoid a crash in the booting server's shared memory interface
		};

		^event

	}

	readFileIfNecessary { |event|
		var buffer = event[\bufferObject];
		if(buffer.notNil) {
			buffer.readWithInfo(onComplete: { event[\notYetRead] = false })
		}
	}

	makeEventForBuffer { |buffer|
		var baseFreq = 60.midicps;
		^(
			buffer: buffer.bufnum,
			bufferObject: buffer,
			notYetRead: doNotReadYet,
			instrument: this.instrumentForBuffer(buffer),
			bufNumFrames: buffer.numFrames,
			bufNumChannels: buffer.numChannels,
			unitDuration: { buffer.duration * baseFreq / ~freq.value },
			hash: buffer.identityHash,
			note: 0
		)
	}

	instrumentForBuffer { |buffer|
		var needs64BitPrecision = buffer.numFrames > 16777216;
		var synthName = if(needs64BitPrecision) { "dirt_sample_long_%_%" } { "dirt_sample_%_%" };
		if(needs64BitPrecision) { "event for long sound file: %".format(buffer.path).postln };
		^format(synthName, buffer.numChannels, this.numChannels).asSymbol
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
			"\nCurrently there are no samples read into memory.".postln;
		} {
			if(doNotReadYet) {
				"samples only registered, will read them on demand.".postln;
			} {
				"\nCurrently there are % sample banks in memory (% MB):"
				"\n\nName (number of variants), range of durations (memory)\n"
			}
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
