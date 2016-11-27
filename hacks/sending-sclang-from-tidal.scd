
// note that anyone who has access to the localhost IP could call arbitrary code on supercollider

(
OSCdef(\interpret, { |msg, time, tidalAddr|
		msg.postln;
		msg[1].asString.interpret
	},
	"/inter",
	NetAddr("127.0.0.1"), // allow only local communication
	recvPort: 57120
).fix
)


~self = NetAddr("127.1.1.0", 57120);

~self.sendMsg("/inter", "({ 1.0.rand } ! 10).postln");



// close it down again
OSCdef(\interpret).remove;


