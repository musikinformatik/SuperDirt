/*
(C) 2015-2020 Julian Rohrhuber and contributors
SuperDirt is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 2 of the License, or (at your
option) any later version.
*/

if(\MembraneHexagon.asClass.isNil) {
	"Dirt could not load some synths from default-synths.scd, because sc3plugins are necessary and missing.".warn
} {
	loadRelative("../library/default-synths-extra.scd");
	loadRelative("../library/default-effects-extra.scd");
};
