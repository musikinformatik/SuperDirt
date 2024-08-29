
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
		var event, index;
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
		event = this.makeEventForBuffer(buffer, metaData);
		buffers[name] = buffers[name].add(buffer);
		bufferEvents[name] = bufferEvents[name].add(event);
		metaData !? { this.prPutMetaData(name, buffers[name].size - 1, metaData) };
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
		metaData !? { this.prPutMetaData(name, synthEvents[name].size - 1, metaData) };
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

	loadSoundFileFolder { |folderPath, name, appendToExisting = false, sortFiles = true|
		var files;

		if(File.exists(folderPath).not) {
			"\ncouldn't read '%' files, path doesn't exist: %.".format(name, folderPath).postln;
			^this
		};

		files = pathMatch(folderPath.standardizePath +/+ "*"); // dependent on operating system
		if(sortFiles) { files.sort };

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
			try {
				var buf, metaData;
				buf = this.readSoundFile(filepath);
				if(buf.notNil) {
					metaData = this.readMetaData(filepath);
					this.addBuffer(name, buf, appendToExisting, metaData);
					appendToExisting = true; // append all others
				};
			} { |erreur|
				erreur.reportError;
			}
		}

	}

	loadSoundFile { |path, name, appendToExisting = false|
		var buf, metaData;
		buf = this.readSoundFile(path);
		if(buf.notNil) {
			metaData = this.readMetaData(path);
			this.addBuffer(name, buf, appendToExisting, metaData);
		}
	}

	readSoundFile { |path|
		var fileExt = (path.splitext[1] ? "").toLower;
		if(fileExtensions.includesEqual(fileExt).not) {
			if(verbose) { "\nignored file: %\n".postf(path) };
			^nil
		}
		^Buffer.readWithInfo(server, path, onlyHeader: doNotReadYet)
	}

	readMetaData { |path|
		^this.readSmplMetaData(path)
	}

	// read the `smpl` chunk of a wave file, containing metadata such as pitch
	// https://www.recordingblogs.com/wiki/sample-chunk-of-a-wave-file
	// currently, there seems to be no direct way to read arbitrary wave chunks, so instead this function parses the data from the log written by libsndfile
	readSmplMetaData { |path|
		var midinote;
		try {
			var noteStr, fractStr, note, fract;
			SoundFile.use(path, { |sf|
				var headers, noteRe, fractRe;
				headers = sf.readHeaderAsString;
				noteRe = "  Midi Note\\s*:\\s*(.+?)\\s*\n";
				fractRe = "  Pitch Fract.\\s*:\\s*(.+?)\\s*\n";
				noteStr = headers.findRegexp(noteRe) !? _[1] !? _[1];
				fractStr = headers.findRegexp(fractRe) !? _[1] !? _[1];
			});
			note = noteStr !? _.asInteger;
			fract = fractStr !? _.asFloat;
			if(note.notNil && fract.notNil) {
				// as of 2022-06-24, the libsndfile calculation that gives the pitch fraction seems to be wrong...
				// https://github.com/libsndfile/libsndfile/blob/33e765ccba9a0eb225694fdbf9e299683a8338ee/src/wav.c#L1399
				// basically, all values other than 0 are inverted and scaled incorrectly.
				// here we assume this is the case and correct the math.
				// TODO: maybe have a flag to skip this, to support a potential fixed libsndfile?
				if(fract > 0) {
					fract = fract.reciprocal * 0.5;
				};
				midinote = note + fract;
			};
		} { |e| e.reportError };
		^if(midinote.notNil) {
			(
				midinote: midinote,
				baseFreqToMetaFreqRatio: (60 - midinote).midiratio
			)
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

	makeEventForBuffer { |buffer, metaData|
		var baseFreq = 60.midicps;
		var baseFreqToMetaFreqRatio = metaData !? _[\baseFreqToMetaFreqRatio] ? 1.0;
		^(
			buffer: buffer.bufnum,
			bufferObject: buffer,
			notYetRead: doNotReadYet,
			instrument: this.instrumentForBuffer(buffer),
			stretchInstrument: this.stretchInstrumentForBuffer(buffer),
			bufNumFrames: buffer.numFrames,
			bufNumChannels: buffer.numChannels,
			baseFreqToMetaFreqRatio: baseFreqToMetaFreqRatio,
			metaDataTuneRatio: {
				if(~metatune.notNil) {
					~metatune.linexp(0.0, 1.0, 1.0, ~baseFreqToMetaFreqRatio)
				} {
					1.0
				}
			},
			unitDuration: { buffer.duration * baseFreq / (~freq.value * ~metaDataTuneRatio.value) },
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

	stretchInstrumentForBuffer { |buffer|
		^format("dirt_stretchsample_%_%", buffer.numChannels, this.numChannels).asSymbol
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
				event[\instrument] = this.instrumentForBuffer(event[\buffer]);
				event[\stretchInstrument] = this.stretchInstrumentForBuffer(event[\buffer]);
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

	prPutMetaData { |name, index, metaData|
		if(metaDataEvents[name].isNil) {
			metaDataEvents[name] = Dictionary[];
		};
		metaDataEvents[name].put(index, metaData);
	}
}
