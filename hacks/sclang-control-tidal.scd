

// this is the default, change it if yu have configured something else in
// tidal <- startTidal superdirtTarget (defaultConfig {cCtrlAddr = "0.0.0.0", cCtrlPort = 6060})
~addr = NetAddr("127.0.0.1", 6010);



// e.g. send cursor positions
(
Tdef(\control_tidal, {

	inf.do { |x|
		~addr.sendMsg("/ctrl", "hello", x % 8);
		0.5.rand.wait
	}

}).play
)

// in tidal
d1 $ slow (0.125) $ sound "can" # n (cF 1 "hello")
