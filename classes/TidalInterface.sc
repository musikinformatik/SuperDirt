/*
An attempt at giving Tidalcycles a direct interface to SuperDirt,
so you could load samples, load synths, kill the server, etc. all from a Tidalcycles Ide

Currently, the SuperDirt class intercepts osc messages containing parameters
sent from Tidal, and sends them t
*/

InterfaceEvent {

	var <event;
	var soundLibrary;

    *new { |event,soundLibrary|
				// "in Interface".postln;
        ^super.newCopyArgs(event,soundLibrary)
    }

	test {
		// server = ~server.value;

		if(soundLibrary != nil) 
			{"soundLibrary exists".postln}
			{"no soundLibrary exists".postln};

	}

	parse {
		// if(event[\scMessage] == \loadSoundFiles){this.loadSoundFiles}
		switch(event[\scMessage])
			{\loadSynthDefs} {this.loadSynthDefs}
			{\loadOnly} {this.loadOnly}
			{\loadSoundFileFolder} {this.loadSoundFileFolder}
			{\loadSoundFiles} {this.loadSoundFiles}
			{\loadSoundFile} {this.loadSoundFile}
			{\freeAllSoundFiles} {this.freeAllSoundFiles}
			{\freeSoundFiles} {this.freeSoundFiles}
			{\postSampleInfo} {this.postSampleInfo}
			{\initFreqSynthWindow} {this.initFreqSynthWindow}
	}

	loadSynthDefs{
		// "in loadSynthDefs".postln;
		if(event[\filePath] != nil)
			{soundLibrary.loadSynthDefs(event[\filePath].asString)}
			{"error: no path passed to loadSynthDefs"};
	}

	loadOnly {
		// "in loadonly".postln;
		if(event[\filePath] != nil)
			{soundLibrary.loadOnly(event[\filePath].asString)}
			{"error: no path passed to loadOnly"};
	}

	loadSoundFileFolder {
	// "in loadSoundFileFolder".postln;
		if(event[\filePath] != nil)
			{soundLibrary.loadSoundFileFolder(event[\filePath].asString)}
			{"error: no path passed to loadSoundFileFolder"};
	}

	loadSoundFiles {
		"in loadSoundFiles".postln;
		if(event[\filePath] != nil)
			{soundLibrary.loadSoundFiles(event[\filePath].asString)}
			{"error: no path passed to loadSoundFiles"};
	}

	loadSoundFile { 
	// "in loadSoundFile".postln;
		if(event[\filePath] != nil)
			{soundLibrary.loadSoundFile(event[\filePath].asString)}
			{"error: no path passed to loadSoundFile"};
	}

	freeAllSoundFiles {
	// "in freeAllSoundFiles".postln;
	soundLibrary.freeAllSoundFiles;
	}

	freeSoundFiles {
	// "in freeSoundFiles".postln;
		if(event[\names] != nil)
			{soundLibrary.freeSoundFiles(event[\names])}
			{"error: no names passed to freeSoundFiles"};
	}

	postSampleInfo {
	// "in postSampleInfo".postln;
	soundLibrary.postSampleInfo;
	}

	initFreqSynthWindow{
		"initalizing frequency scope window".postln;
		FreqScopeWindow().new;
	}

	debug { 
		event.postln;
		this.parse;
	}


	*predefinedServerParameters{
		// not complete, but avoids obvious collisions
		^#[\load, \free];
	}



}

