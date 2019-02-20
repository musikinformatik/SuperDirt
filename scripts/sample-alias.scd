

// make an alias for a sample name

(
~makeAlias = { | ...pairs |
	pairs.pairsDo { |from, to|
		var val = ~dirt.soundLibrary.buffers[from];

		if(val.isNil) { warn("no such sample " ++ from ) } {
			if(~dirt.soundLibrary.buffers[to].notNil) {
				warn("name already exists " ++ to )
			} {
				val.do { |buf|
					~dirt.soundLibrary.addBuffer(to, buf, true)
				};
				postln("linked" ++ to ++ " -> " ++ from);
			}
		}
	};
};
)


~makeAlias.(\bd, \b);

// for many:

~makeAlias.(\hh, \h, \can, \c);