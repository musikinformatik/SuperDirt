
/*

DirtError.sc - Represents an error that re-posts only after a certain
timeout. This can be used to avoid flooding the post window.

(C) 2015-2020 Julian Rohrhuber and contributors. Distributed under the
terms of GNU General Public License version 2, or (at your option) any
later version. Details: http://www.gnu.org/licenses/

Usage:

error = DirtPartTimeError(3, "this messagse was ill-intended");

// in your code, later:

error.throw;

// it will throw, but only post every three seconds at maximum

*/

DirtPartTimeError : Error {

	var <>timeout, before;


	*new { |timeout = 1, what|
		^super.new(what).timeout_(timeout)
	}

	reportError {
		var now = Main.elapsedTime;
		if(before.isNil or: { now - before > timeout }) {
			before = now;
			super.reportError;
		}
	}


}
