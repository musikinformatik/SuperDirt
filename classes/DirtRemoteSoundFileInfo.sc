DirtRemoteSoundfileInfo {

	var <library;
	var sendResponder;


	*new { |library, port|
		^super.newCopyArgs(library)
	}

	start { |port (57120) |
		sendResponder = OSCFunc({ |msg,time,addr|
			this.sendRemoteSoundFileInfoReply(addr, msg.drop(1))
		}, "/dirt_soundfileinfo_request", recvPort: port).fix;
	}

	stop {
		sendResponder.free;
	}

	sendRemoteSoundFileInfoReply { |netAddr|
		var info;
		info = this.convertBuffersToInfo(library);
		netAddr.sendMsg("/dirt_soundfileinfo_reply", *info);
	}

	convertBuffersToInfo { |library|
		var info = Array.new(512);
		library.bufferEvents.keysValuesDo { |key, eventArray|
			eventArray.do { |event|
				var bufnum = event[\buffer];
				if(bufnum.notNil) {
					info = info.add(key);
					info = info.add(event[\numFrames]);
					info = info.add(event[\numChannels]);
					info = info.add(bufnum);
				};
			};
		};
		^info
	}

	convertInfoToBuffers { |info|
		var buffers = Array.new(512);
		info.clump(4).do { |data|
			var key, numFrames, numChannels, bufnum, buf;
			# key, numFrames, numChannels, bufnum = data;
			buf = Buffer(nil, numFrames, numChannels, bufnum);
			buffers = buffers.add(key.asSymbol);
			buffers = buffers.add(buf);
		};
		^buffers
	}

	sendRequest { |addr, callback, timeout = 5|

		var resp = OSCFunc({ |msg|
			var buffers = this.convertInfoToBuffers(msg.drop(1));
			callback.value(buffers)
		}, "/dirt_soundfileinfo_reply", recvPort: addr.port);

		addr.sendMsg("/dirt_soundfileinfo_request");
		fork {
			timeout.wait;
			resp.free;
		}

	}

}
