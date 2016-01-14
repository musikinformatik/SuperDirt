/*

adding a post function

*/

(
~dirt.addModule('post',
	{ |dirtEvent|
		[\sound,
			\cps, \offset, \begin, \end, \sustain,
			\amp, \speed, \endSpeed, \accelerate,
			\resonance, \hcutoff, \hresonance, \bandqf, \bandq,
			\crush, \coarse
		].do { |key, i|
			var val = key.envirGet;
			if(val.notNil) { val = val.round(0.001) };
			"%: % ".format(key, val).post;
			if(i % 4 == 0) { "\n".post };
		};
		"\n\n".post;

});
)



// remove it again:
~dirt.removeModule(\post);
(
~dirt.addModule('post',
	{ |dirtEvent|
		"------------".postln;
		dirtEvent.event.pairsDo { |key, val, i|
			"%: % ".format(key, val).post;
			if(i % 4 == 0) { "\n".post };
		}

});
)

// remove it again:
~dirt.removeModule(\post);
