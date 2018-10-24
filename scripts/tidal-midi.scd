
// version 0.3

// first, initialize your midi device.
(
MIDIClient.init;
MIDIClient.list; // to check, which are there, you can query them
)


// create a midi out connection
~midiOut = MIDIOut.newByName("FastLane USB", "Port A"); // substitute your own device here

 // you may want to adjust the latency here
~midiOut.latency = 0.0;



// define one instrument called "midi" (you may call it what you like)
// it uses the built in event type "midi" (this is predefined).

~dirt.soundLibrary.addMIDI(\midi, ~midiOut);

// You can then test it on the tidal side with this:

Send some notes:
```
d1 $ note "c d e f" # s "midi"
```
Send them to the tenth midi channel (counting from 0)
```
d1 $ note "c d e f" # s "midi" # midichan 9
```
Send midi clock:
```
d1 $ midicmd "[start/4,midiClock*48]" # s "midi" 
```

Send control values
```
d1 $ ccn "28*16" # ccv 127 # s "midi" # midichan 9
```


// note: parameter names may change in the future!

// In supercollider terms, the following midicmds and their parameters are supported
// (the usual note/freq and legato/sustain parameters are taken into account)

polyTouch: midichan, midinote, polyTouch
program: midichan, progNum
bend: midichan, val
sysex: uid, array
noteOn: midichan, midinote, amp // default
allNotesOff: midichan
smpte: frames, seconds, minutes, hours, frameRate
songPtr: songPtr
control: midichan, ctlNum, control
touch: midichan, val
noteOff: midichan, midinote, amp // sent automatically, after sustain.


// Tidal defines the following parameters:
```
midicmd, midichan, progNum, val, uid, array, frames, seconds, minutes, hours, frameRate, songPtr, ctlNum, control, cc, ccn, ccv
```
