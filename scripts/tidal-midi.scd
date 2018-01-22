
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


// note: parameter names may change in the future!

// in tidal, define the following parameters:

    (midicmd, midicmd_p) = pS "midicmd" (Nothing)
    (midichan, midichan_p) = pF "midichan" (Nothing)
    (progNum, progNum_p) = pF "progNum" (Nothing)
    (val, val_p) = pF "val" (Nothing)
    (uid, uid_p) = pF "uid" (Nothing)
    (array, array_p) = pF "array" (Nothing)
    (frames, frames_p) = pF "frames" (Nothing)
    (seconds, seconds_p) = pF "seconds" (Nothing)
    (minutes, minutes_p) = pF "minutes" (Nothing)
    (hours, hours_p) = pF "hours" (Nothing)
    (frameRate, frameRate_p) = pF "frameRate" (Nothing)
    (songPtr, songPtr_p) = pF "songPtr" (Nothing)
    (ctlNum, ctlNum_p) = pF "ctlNum" (Nothing)
    (control, control_p) = pF "control" (Nothing)


// the following midicmds and their parameters are then supported
// the usual note/freq and legato/sustain parameters are taken into account

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


