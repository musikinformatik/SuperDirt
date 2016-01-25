/*

Remote control Dirt from Tidal via OSC

Open and close Dirt Channels (DirtOrbit instances) on the fly.

This assumes you have stored dirt in a variable ~dirt

*/


// send OSC: "/new_dirt", name, port, outBus
// outBus is an arbitrary channel offset (if it exceeds your hardware channels, it'll play on a private bus).
// The number of synth channels is fixed per SuperDirt instance
// so you need several of them if you want different number of channels.

(
~allChannels = ~allChannels ? ();
OSCdef(\newdirt, { |msg, time, tidalAddr|

	var name, port, outBus, old;
	#name, port, outBus = msg[1..];
	old = ~allChannels[name];
	if(old.notNil) { old.free };
	old[name] = DirtOrbit(~dirt, port, outBus, tidalAddr);
}, '/new_dirt', srcID: nil).fix; // srcID you may want to add NetAddr("127.0.0.1", <dirt-port>)

// send OSC: "/remove_dirt", name

OSCdef(\removedirt, { |msg, time, tidalAddr|

	var old, name = msg[1];
	old = ~allChannels[name];
	if(old.notNil) { old.free };
}, '/remove_dirt', srcID: nil).fix; // srcID you may want to add NetAddr("127.0.0.1", <dirt-port>)

)