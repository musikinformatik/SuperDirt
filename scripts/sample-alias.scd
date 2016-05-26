

// make an alias for a sample name

(
~makeAlias = { | ...pairs |
	pairs.pairsDo { |from, to|
		var val = ~dirt.buffers[from];

		if(val.isNil) { warn("no such sample " ++ from ) } {
			if(~dirt.buffers[to].notNil) {
				warn("name already exists " ++ to )
			} {
				~dirt.buffers[to] = val;
				postln("linked" ++ to ++ " -> " ++ from);
			}
		}
	};
};
)


~makeAlias.(\bd, \b);

// for many:

~makeAlias.(\hh, \h, \can, \c);