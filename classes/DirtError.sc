
/*

DirtError.sc - Represents an error that re-posts only after a certain
timeout. This can be used to avoid flooding the post window.

(C) 2015-2020 Julian Rohrhuber and contributors

SuperDirt is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
