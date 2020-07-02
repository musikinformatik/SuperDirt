/*
DirtModule.sc - encapsulates two functions:
1) for testing for parameters (whether or not to start a synth at all)
2) activated when the parameters are found in the message from tidal

(c) 2015-2020 Julian Rohrhuber and contributors. Distributed under the
terms of GNU General Public License version 2, or (at your option) any
later version. Details: http://www.gnu.org/licenses/
*/


DirtModule {
	var <name, <func, <test;

	*new { |name, func, test|
		^super.newCopyArgs(name, func, test ? true)
	}

	value { |orbit|
		if(test.value, { func.value(orbit) })
	}

	== { arg that;
		^this.compareObject(that, #[\name])
	}

	hash {
		^this.instVarHash(#[\name])
	}

	printOn { |stream|
		stream  << this.class.name << "(" <<< name << ")"
	}

	storeArgs {
		^[name, func, test]
	}
}
