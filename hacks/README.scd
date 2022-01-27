/*


The examples in the current hacks / folder can be used while you play already, and most of it can be live coded.
These files are not "include files". If you want to use any code of it into your setup, copy it and add it to
your supercollider startup file.  How to do this is explained below.
The startup file is to be found in the menu under: File>Open startup file

*/



// assuming that you want to use some example hack from function-hacks.scd

// for convenience, here is a line of code that will open it for you.
// resolveRelative expands the path to the directory of the current document
Document.open("function-hacks.scd".resolveRelative);


// let's say you want to add the first example to your startup file
// you can either copy and paste the code directly your startup file (see comment there)

~dirt.soundLibrary.addSynth(\test, (play: { "////////////// do whatever \\\\\\\\\\\\\\\\".postln }));

// if there are more than one of those, they should be separated by semicolons.

~dirt.soundLibrary.addSynth(\test, (play: { "////////////// do whatever \\\\\\\\\\\\\\\\".postln }));
~dirt.soundLibrary.addSynth(\best, (play: { "////////////// do nothing whatsoever \\\\\\\\\\\\\\\\".postln }));


// or you can copy it into a separate file, and load it from the startup file:
"path/to/myfile.scd".load;

// if you put that file next to your startup file, just write:
"myfile.scd".loadRelative;

// to make sure your dirt is running when the file is loaded
// load it from inside the waitForBoot function in the superdirt_startup (see example startup)




/*

live coding tidal in SuperDirt

*/

// you can call most of the code in the hacks directory while running
// while tidal is playing sound "test" # n "0 1 0 2", rewrite what it posts here
~dirt.soundLibrary.addSynth(\test, (play: { "////// whatever \\\\\\\\".postln }));
~dirt.soundLibrary.addSynth(\test, (play: { "////// whatever % \\\\\\\\".format(~n).postln }));

// also use SynthDefs from these files and their names and parameters become accessible from tidal
// (for new parameter names you may have to add them there)
// see https://github.com/musikinformatik/SuperDirt/blob/develop/hacks/adding-global-effects.scd for accessing parameters of synthdefs.



 