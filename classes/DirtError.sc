
/*

This is an error that re-posts only after a certain timeout. This can be used to avoid flooding the post window.

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
