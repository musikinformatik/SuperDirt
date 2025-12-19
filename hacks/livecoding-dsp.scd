/*

livecode DSP graphs!

(see livecoding-dsp.tidal for the corresponding Tidal code)

since OSC messages can contain arbitrary strings, we can put sclang code in
them and .interpret it to build synth graphs on the fly.

!!! WARNING !!!
this is a huge security hole if you configure SuperDirt to listen on a non-
loopback network interface - anyone who can send you OSC will be able to
execute arbitrary code on your system.

*/

// once SuperDirt has started, we can enable DirtLiveDsp
(
~liveDsp = DirtLiveDsp(~dirt);
~liveDsp.start;
)