

(
s.options.numBuffers = 1024 * 16;
s.options.memSize = 8192 * 16;
~dirt.free; // free old instance
s.waitForBoot {
	~dirt = SuperDirt(2, s, (vowelRegister: \bass));
	~dirt.loadSynthDefs;
	~dirt.loadSoundFiles;
	~dirt.start;
}
)


(
Tdef(\x, {
	loop {
		~dirt.(nil, 1, 'cy:10', 0, 0.3.rand, 1.0.rand, 1 + 1.3.rand2, 2.rand2, accelerate:0);
		(0.2 * [1, 2, 1/3]).choose.wait;
	}
}).play;
)

~dirt.(nil, 1, 'cy:10', speed: 1);
~dirt.(nil, 1, 'cy:10', speed: -1);

~dirt.(nil, 1, 'cy:10', speed: 1, accelerate: -0.2);
~dirt.(nil, 1, 'cy:10', speed: 1, accelerate: -3);
~dirt.(nil, 1, 'sd:8', speed: 1);
~dirt.(nil, 1, 'cy:10', speed: 2);


// test effects:
~dirt.(nil, 1, 'cy:10', speed: 0.2, crush: 4);
~dirt.(nil, 1, 'cy:10', speed: 0.2, coarse: 8);

~dirt.(nil, 1, 'cy:10', speed: 0.2, crush: 4, coarse: 38);
~dirt.(nil, 1, 'cy:10', speed: 1, crush: 4);
~dirt.(nil, 1, 'cy:10', speed: 1, hcutoff: 1000, hresonance: 20);
~dirt.(nil, 1, 'cy:10', speed: 1, hcutoff: 3000, hresonance: 10);
~dirt.(nil, 1, 'cy:10', speed: 1, bandqf: 3000, bandq: 100);
~dirt.(nil, 1, 'cy:10', speed: 1, bandqf: 3000, bandq: 100, coarse: 13);
~dirt.(nil, 1, 'cy:10', speed: 1, bandqf: 3000, bandq: 100, crush: 1);
~dirt.(nil, 1, 'cy:10', speed: 1, hcutoff: 1000, hresonance: 20, coarse: 0.10);


// test vowels
~dirt.(nil, 1, 'cy:10', speed: 1, vowel: \a);
~dirt.(nil, 1, 'cy:10', speed: 1, vowel: \i, resonance: 1, cutoff: 200, gain: 2);
~dirt.(nil, 1, 'cy:10', speed: 1, vowel: \a, resonance: 0.1);
~dirt.(nil, 1, 'cy:10', speed: 1, vowel: \o, resonance: 0.1);
~dirt.(nil, 1, 'cy:10', speed: 1, vowel: \o, resonance: 0.1, coarse: 30);

(
Tdef(\x, {
	loop {
		~dirt.(nil, 1, 'sd:8', start: 0, end: 1, speed: 1, vowel: "aeiou".choose.asSymbol, resonance: 0.6, cutoff: 540, gain: 1);
		1.wait;
		//(0.3 * [1, 2, 1/3]).choose.wait;
	}
}).play;
)

(
Tdef(\x, {
	loop {
		~dirt.(nil, 1, 'sd:8', start: 0, end: 1.0.rand, speed: 2.5, vowel: "aeiou".choose.asSymbol, resonance: 0.5, cutoff: 202);
		0.1.wait;
	}
}).play;
)

// tough test
(
Tdef(\x, {
	loop {
		~dirt.(nil, 1, 'sd:8', start: 0, end: 1.0.rand, speed: 12.5, vowel: "aeiou".choose.asSymbol, resonance: 1, cutoff: 202);
		0.02.wait;
	}
}).play;
)


d.vowels.freqs.flat.maxItem
d.vowels.amps.flat.maxItem

s.reboot
Tdef(\x).stop;


// test delay:

~dirt.(nil, 1, 'cy:10', speed: 1, delaytime: 0.8, delay: 1);
~dirt.(nil, 1, 'cy:10', speed: 1, delaytime: 0.8, delay: 0);
~dirt.(nil, 1, 'cy:10', speed: 1, delaytime: 0.2, delay: 1);





// cutgroup tests
~dirt.(nil, 1, 'cy:10', speed: 0.02, cutgroup: -8); // really slow, to keep it on: see synth reading
~dirt.(nil, 1, 'cy:10', speed: 0.02, cutgroup: -8); // cut the old one: number stays the same
~dirt.(nil, 1, 'cy:10', speed: 0.02, cutgroup: -8); // ... again


//  With negative, only stop the same sample from playing in the same cutgroup
~dirt.(nil, 1, 'cy:9', speed: 0.02, cutgroup: -8); // a different sample, is added
~dirt.(nil, 1, 'cy:9', speed: 0.02, cutgroup: -8); // the same sample, frees

//  with positive integers, stop samples playing that are in the same cutgroup.
~dirt.(nil, 1, 'cy:10', speed: 0.02, cutgroup: 8); // should free all others

// test unit

/*
s unit -
"r" makes unit of speed and start/end time in terms of
ratio (the default described above),

"c" in terms of cycles per second
(i.e. 1 to play back at a speed that makes the sample exactly fill one
cycle), and

"s" in terms of seconds

*/

// \r

(
Tdef(\x, {
	var name = 'cy:10';
	var cps = 2;
	20.do {
		~dirt.(nil, cps:cps, name:name, unit: \r, start: 0, end: 1);
		cps = cps + 0.3;
		(1/cps).wait;
	}
}).play
)


// \c
(
Tdef(\x, {
	var name = 'cy:10';
	var cps = 2;
	20.do {
		~dirt.(nil, cps:cps, name:name, unit: \c, start: 0, end: 1);
		cps = cps + 0.3;
		(1/cps).wait;
	}
}).play
)

// \s
(
Tdef(\x, {
	var name = 'cy:10';
	var cps = 0.2;
	loop {
		~dirt.(nil, cps:cps, name:name, unit: \s, start: 0, end: 0.2);
		0.2.wait;
	}
}).play
)


// test replacement:


// you can livecode this while running tidal.
(
SynthDef(\imp, { |speed = 1, start=0, end=1, pan, accelerate, amp = 0.1, offset|
	var env, sound, dur, rate, phase;
	dur = (end - start) / speed;
	env = EnvGen.ar(Env.linen(0, 0.2, 0.8, amp, -4), timeScale:dur, doneAction:2);
	phase = Line.ar(start, end, dur);
	rate = (start + 1) * (speed + Sweep.kr(1, accelerate));
	sound = Blip.ar(rate.linexp(0, 1, 15 * [1, 2, 5], 200), 200 * phase).sum;
	env = env * ~dirt.gateCutGroup; // this synth can be freed by cutgroup mechanism
	~dirt.panOut(sound, pan, env)
}).add;
)


~dirt.(nil, 1, 'imp', speed: 1, start: 0, end: 1);


~dirt.(nil, 1, 'imp', speed: 1, start: 0.5, end: 1);
~dirt.(nil, 1, 'imp', speed: 0.1, start: 0, end: 1, accelerate: 3);

~dirt.(nil, 1, 'imp', speed: 1, start: 0, end: 0.3.rand, delay: 1, delaytime: 3);



(
Tdef(\x, {
	loop {
		~dirt.(nil, 1, 'imp', 0,
			speed: rrand(0.1, 2.0),
			start:1.0.rand,
			end: 2.0.rand,
			accelerate:2.0.rand,
			hcutoff: 4000.0.rand,
			hresonance: 0.5.rand,
			delay: 1.0.rand,
			delaytime: 0.2
		);
		0.5.wait;
	}
}).play;
)

(
Tdef(\x, {
	loop {
		~dirt.(nil, 1, 'inr', 0,
			speed: rrand(0.5, 2.0),
			start:1.0.rand,
			end: 2.0.rand,
			//accelerate:2.0.rand,
			//hcutoff: 4000.0.rand,
			//hresonance: 0.5.rand,
			delay: 1.0.rand,
			//delaytime: 0.2
		);
		0.15.wait;
	}
}).play;
)


~buffers[\cy][0].duration;
~buffers[\cy][0].samplerate;

NetAddr.langPort == 57120; // hope it's true

// network test
n = NetAddr("127.0.0.1", 57120);
// Should pan left and right?
n.sendMsg(\play, 1, 'cy:10',0,0,1,1,0);
n.sendMsg(\play, 1, 'cy:10',0,0,1,1,1);

// feeding back
n.sendMsg(\play, 1, 'cy:10',0,0,1,1,0.5,0,"o");

n.sendMsg(\play, 1, 'cy:10',0,0,1,1,0.5,0);


n.sendMsg(\play, 1, 'breaks125');

n.sendMsg(\play, 1, \imp);

(
n.sendBundle(1.2, [\play, 1, 'cy']);
n.sendBundle(1.2, [\play, 1, 'cy']);
)

