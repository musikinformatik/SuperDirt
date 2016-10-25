
// by setting the onset parameter, you can nudge backward or forward individual samples


// example.
// in tidal:
d1 $ sound "techno:5" speed

d2 $ sound "bd bd"

~dirt.buffers[\techno][5].onset = 0.22;



~dirt.postSampleInfo