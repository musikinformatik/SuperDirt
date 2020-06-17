


/*

Because tidalcycles may hit performance limits in superdirt,
there is a way to drop synths if necessary. This can avoid trouble.

You can fine-tune this by changing the dropWhen function (it should return a boolean).
Note that the function is called for every event, so probably better keep it simple.

By default no synths are dropped (dropWhen is false).


*/

// this will keep peak cpu very very low, and drop a lot of events
~dirt.dropWhen = { ~dirt.server.statusWatcher.peakCPU > 3.3 }; // limit to 3.3 % cpu


// this is probably more realistic
~dirt.dropWhen = { ~dirt.server.statusWatcher.peakCPU > 90 }; // limit to 90 % cpu


// fine tune try different parameters, just a guess here:
(
~dirt.dropWhen = {
	var watcher = ~dirt.server.statusWatcher;
	watcher.peakCPU > 95
	or:
	{ watcher.avgCPU > 85 }
	or:
	{ watcher.numSynths > 10000 }
}
);

// mess things up:

~dirt.dropWhen = { 0.1.coin }; // randomly drop 10 % of the messages on average

// allow only a fixed budget of events
(
var count = 0;
~dirt.dropWhen = {
	count = count + 1;
	count > 350
}
)

// finally: do not drop any synths:

~dirt.dropWhen = false;