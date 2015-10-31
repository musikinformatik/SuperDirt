/*

adding a post function

*/

(
~dirt.addModule('post',
	{ |dirtEvent|
		[\sound,
			\cps, \offset, \start, \end, \sustain,
			\amp, \speed, \endSpeed, \accellerate,
			\resonance, \hcutoff, \hresonance, \bandqf, \bandq,
			\crush, \coarse
		].do { |key, i|
			if(dirtEvent.dirtBus.defaultParentEvent.at(key) != key.envirGet) {
				"%: % ".format(key, key.envirGet).post;
				if(i % 8 == 0) { "\n".post };
			};
		};
		"\n\n".post;

});
)

// remove it again:
~dirt.removeModule(\post);
