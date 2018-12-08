if(\MembraneHexagon.asClass.isNil) {
	"Dirt could not load some synths from default-synths.scd, because sc3plugins are necessary and missing.".warn
} {
	loadRelative("../library/default-synths-extra.scd");
	loadRelative("../library/default-effects-extra.scd");
};
