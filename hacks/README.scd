/*


The examples in the current hacks / folder can be used while you play already, and most of it can be live coded.
If you want to include any code of it into your setup, it is recommendable to copy it
and add it to your supercollider startup file. These files are not incoude files. How to do this is explained below.
The startup file is to be found in the menu under: File>Open startup file

*/



// assuming that you want to use some example hack from function-hacks.scd

// for convenience, here is a line of code that will open it for you.
// resolveRelative expands the path to the directory of the current document
Document.open("function-hacks.scd".resolveRelative);


// let's say you want to add the first example to your startup file
// you can either copy and paste the code directly your startup file (see comment there)

~dirt.soundLibrary.addSynth(\test, (play: { "////////////// do whatever \\\\\\\\\\\\\\\\".postln }));

// or you can copy it into a separate file, and load it from the startup file:
"path/to/myfile.scd".load;

// if you put that file next to your startup file, just write:
"myfile.scd".loadRelative;

// to make sure your dirt is running when the file is loaded
// load it from inside the waitForBoot function in the superdirt_startup (see example startup)
