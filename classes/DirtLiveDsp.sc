DirtLiveDsp {
	var <dirt, <gdspSource, <>defaultGdspSynth, <>gdspDiversion, <>dspDiversion, <allowDangerousRemoteCodeExecution;
	
	*new { |dirt|
		^super.newCopyArgs(dirt).init
	}

	init {
		gdspSource = nil ! dirt.orbits.size;

		// the default no-effect global effect synth
		defaultGdspSynth = { |dryBus, effectBus, gate=1|
			var dry, wet, sum;
			dry = In.ar(dryBus, dirt.numChannels);
			wet = In.ar(effectBus, dirt.numChannels);
			EnvGen.kr(Env.asr, gate, doneAction: Done.freeSelf);
			DirtPause.ar(sum, graceTime: 4);
		};

		gdspDiversion = { |o, dirtEvent|
			var gdspEffect;
			// if the effect code has changed since the last event received,
			// recreate the effect using the new code.
			if(~gdsp != gdspSource[o.orbitIndex]) {
				// remember the code so we can keep this synth running until the
				// code changes.
				gdspSource[o.orbitIndex] = ~gdsp;
				
				"redefine %".format("dirt_live_global_dsp_%_%".format(o.orbitIndex, ~numChannels)).postln;
				SynthDef("dirt_live_global_dsp_%_%".format(o.orbitIndex, ~numChannels),
					if(~gdsp.notNil) {
						// if we have some code, wrap it in a function
						// definition to provide the dry signal in the 'in'
						// variable, and interpret.
						//
						// the newline before the closing bracket allows the
						// synth code to include single-line comments.
						{ |dryBus, effectBus, gate=1|
							var dry, wet, sig;
							dry = In.ar(dryBus, ~numChannels);
							// wet = In.ar(effectBus, ~numChannels);
							sig = "{ |in, dryBus, effectBus| %\n}".format(~gdsp.asString).interpret.(dry, dryBus, effectBus);
							sig = sig * EnvGen.kr(Env.asr, gate, doneAction: Done.freeSelf);
							ReplaceOut.ar(dryBus, sig);
						}
					} {
						// if we have no code, restore the default no-effect synth
						defaultGdspSynth
					}
				).add;
				
				gdspEffect = o.globalEffects.detect { |fx| fx.name.asString.beginsWith("dirt_live_global_dsp_") };
				
				// once any new synthdefs are ready...
				{
					// we want to allow the ~gdsp code to use event variables as
					// controls in NamedControl style, e.g. \freq.kr. this requires
					// specifying the control names in the GlobalDirtEffect's
					// paramNames, which we can do automagically with the help of
					// SynthDescLib!
					gdspEffect.paramNames = SynthDescLib.global[(gdspEffect.name.asString ++ ~numChannels).asSymbol].controls.collect(_.name);
					
					// finally, start the effect synth
					gdspEffect.play(o.group, o.outBus, o.dryBus, o.globalEffectBus, o.orbitIndex);
				}
			};
		};

		dspDiversion = { |o, dirtEvent|
			if(~dsp.notNil) {
				// generate temporary synthdef name. by default, these run from
				// 'temp__0' to 'temp__511' and then loop back, so old names
				// eventually get reused and we dont accumulate synthdefs
				// indefinitely.
				~dspSynthDef = SystemSynthDefs.generateTempName.asSymbol;
				
				// build the synthdef. this synth will run after conventional
				// SuperDirt synths specified with 's' (e.g. dirt_sample), and
				// can process their output!
				SynthDef(~dspSynthDef, { |out, pan|
					var in, sig;
					// wrap the code to be interpreted in a function definition
					// to provide two special variables:
					//
					//   - out: output (and input) bus
					//   - in: input signal from the previous synth
					//
					// everything else is accessible via the event, e.g. ~freq.
					in = In.ar(out, ~numChannels);
					sig = "{ |in, out| %\n}".format(~dsp.asString).interpret.(in, out);
					sig = DirtPan.ar(sig, ~numChannels, pan);
					ReplaceOut.ar(out, sig);
				}).add;
			};

			// once any new synthdefs are ready...
			{
				// we have nothing to do here, as the default SuperDirt path
				// will play the synths afterwards. but we still need to return
				// a callback to signal that a sync is needed.
				//
				// on playback, the synthdef name stored in ~dspSynthDef will
				// activate the 'live-dsp' module, defined in the 'start' method.
			}
		};

		allowDangerousRemoteCodeExecution = false;
	}

	start {
		var event;
		if(allowDangerousRemoteCodeExecution.not && { this.listeningOnLoopback.not }) { 
			"Refusing to start DirtLiveDsp, because SuperDirt seems to listening on a non-loopback network address. This would allow anyone who can send OSC messages to SuperDirt to run arbitrary code on your system. If you really want to do this, please ensure every device on your network is trusted, and call enableDangerousRemoteCodeExecution(true)".error;
		} {
			dirt.orbits.do { |o|
				event = o.defaultParentEvent;
				
				// handle ~gdsp (code for the orbit's global effect synthdef)
				event[\syncableDiversions] = event[\syncableDiversions].add(gdspDiversion);

				// handle ~dsp (code for the module synthdef)
				event[\syncableDiversions] = event[\syncableDiversions].add(dspDiversion);
			};

			// define the module which will play our temporary synthdefs.
			dirt.addModule('live-dsp', { |dirtEvent|
				var args, val;

				// support NamedControls (e.g. \cutoff.kr) by detecting all the
				// controls used in the ~dsp code, and passing their values as
				// arguments.
				args = SynthDescLib.global[~dspSynthDef].controls.collect { |c|
					val = currentEnvironment[c.name];
					[c.name, val]
				}.flatten;
				
				dirtEvent.sendSynth(~dspSynthDef, args);
			}, { ~dspSynthDef.notNil });

			dirt.orderModules(['sound', 'live-dsp']);

			// set up global effects
			{
				// even if our ~dsp code does not use an input signal, a conventional synth
				// needs to be specified in 's', otherwise Tidal will not send the event at all.
				// thus, it is convenient to have a silence synthdef.
				SynthDef(\dirt_silence, { |out|
					FreeSelf.kr(1);
					Out.ar(out, Silent.ar(dirt.numChannels));
				}).add;

				// initialize livecodable global effects with the default no-effect synth
				dirt.orbits.do { |o|
					// each orbit gets its own synthdef name
					SynthDef("dirt_live_global_dsp_%_%".format(o.orbitIndex, dirt.numChannels).asSymbol, defaultGdspSynth).add;
				};
				
				// wait for synthdefs to be added
				dirt.server.sync;
				
				// create effects (or recreate if they already exist)
				dirt.orbits.do { |o|
					var insertIx, effect;
					o.globalEffects = o.globalEffects.reject { |fx|
						if(fx.name.asString.beginsWith("dirt_live_global_dsp_")) {
							"release %".format(fx).postln;
							fx.release;
							true;
						} {
							false;
						};
					};
					effect = GlobalDirtEffect("dirt_live_global_dsp_%_".format(o.orbitIndex).asSymbol, []).alwaysRun_(true);
					o.globalEffects = o.globalEffects.insert(0, effect);
					o.initNodeTree;
				};

				"DirtLiveDsp started".postln;
			}.forkIfNeeded;
		}
	}

	enableDangerousRemoteCodeExecution { |enable|
		if(enable) {
			"DirtLiveDsp remote code execution is enabled. This is an insecure configuration that allows anyone who can send OSC messages to SuperDirt to run arbitrary code on your system. Please ensure every device on your network is trusted.".warn;
		};
		allowDangerousRemoteCodeExecution = enable;
	}

	listeningOnLoopback {
		^dirt.senderAddr.hostname == "127.0.0.1"
	}
}
