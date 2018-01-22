
(
var w, p, v, iv, dv;
var load, update, names, soundfile, index = 0, currentBuffer, currentBufferSet, synth;

load = { |path|
	path.postln;
	soundfile !? { soundfile.close };
	soundfile = SoundFile.new;
	soundfile.openRead(path);
	v.soundfile = soundfile;
	v.read(0, soundfile.numFrames);
	v.refresh;
};

update = {
	iv.string = "no: %".format(index.asString);
	dv.string = "% sec".format(currentBuffer.duration.round(0.01));
};


w = Window("dirt sample browser");
w.layout = VLayout();
w.front;

w.view.keyDownAction = { |doc, char, mod, unicode, keycode, key|
	var i;
	switch(keycode,
		126, { p.value = p.value - 1 % names.size; p.action.value(p) },
		125, { p.value = p.value + 1 % names.size; p.action.value(p) },
		123, { index = index - 1 % currentBufferSet.size; p.action.value(p) },
		124, { index = index + 1 % currentBufferSet.size; p.action.value(p)},
		49, { synth = currentBuffer.play; }, // space
		{
			if(char.isAlpha) {
				i = names.detectIndex { |x| x.asString[0] == char };
				i !? { p.value = i }
			}
		}
	);
	update.value;

};

iv = StaticText(w).maxWidth_(40);
dv = StaticText(w).maxWidth_(100);
v = SoundFileView(w);
p = PopUpMenu(w);
p.items = names = ~dirt.buffers.keys.asArray.sort;
p.action = { |v|
	currentBufferSet = ~dirt.buffers @ v.item;
	currentBuffer = currentBufferSet @@ index;
	load.(currentBuffer.path)
};
p.value = 0;
p.action.value(p);
update.value;
w.layout.add(HLayout(p, iv, dv));
w.layout.add(v);

)
