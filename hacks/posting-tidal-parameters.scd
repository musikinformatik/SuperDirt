/*

adding a post function

*/

(
~dirt.addModule('post',
	{ |dirtEvent|
		"\n------------\n".post;
		dirtEvent.event.pairsDo { |key, val, i|
			"%: % ".format(key, val).post;
			if(i % 4 == 0) { "\n".post };
		}

});
)

// remove it again:
~dirt.removeModule(\post);
