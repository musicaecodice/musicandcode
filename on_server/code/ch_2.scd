// ====================================
// =========================> CHAPTER 2
// ====================================

// -------------------------> Init
(
s.boot;
s.meter;
s.scope;
s.plotTree;
)

(
SynthDef.new(\model, {arg freq=500, amp=0, dur=1, pan=0, pantime=0.0,
                          out=0, t_gate=0, done=2;
                      var sig, env;
                          sig = SinOsc.ar(freq);
                          env = Env.new([0.0,1.0,0.5,0.7,0],
                                        [0.1,0.1,0.3,1.0].normalizeSum * dur,
                                        -4
                                        );
                          env = EnvGen.kr(env, t_gate, doneAction:done);
                          sig = sig * env * amp;
                          sig = Pan2.ar(sig, pan.varlag(pantime));
                      Out.ar(out, sig)
                      }).add;
)

// -------------------------> Dynamic voice allocation
(
Synth.new(\model, [\freq, rrand(890,1234),
                   \amp, 0.5,
                   \dur, rrand(0.1,2),
                   \pan, rand2(1.0),
                   \pantime, 0.1,
                   \done, 2,
                   \t_gate,1 ])
)

// -------------------------> Static voice allocation (monophonic)
a = Synth.new(\model, [\done, 0]);

(
a.set(\freq, rrand(890,1234),
      \amp, 0.5,
      \dur, rrand(0.1,2),
      \pan, rand2(1.0),
      \pantime, 0.1,
      \t_gate,1)
)

a.free;
s.freeAll;

// -------------------------> Instrument model with sustain
(
SynthDef.new(\sust, {arg freq=500, amp=0, pan=0, pantime(0.0),
                     out=0, gate=0, done=2;
                     var sig, env;
                         sig = SinOsc.ar(freq);
                         env = Env.adsr;
                         env = EnvGen.kr(env, gate, doneAction:done);
                         sig = sig * env * amp;
                         sig = Pan2.ar(sig, 0);
                     Out.ar(0, sig)
                     }).add;
)

a = Synth.new(\sust, [\done, 0]);

a.set(\amp, 0.5, \gate, 1);
a.set(\gate, 0);
a.free;

// -------------------------> Instrument model without sustain
(
SynthDef.new(\nosust,  {arg freq=500, amp=0, dur=1, pan=0, pantime(0.0),
                            out=0, t_gate=0, done=2;
                        var sig, env;
                            sig = SinOsc.ar(freq);
                            env = Env.perc(0.1*dur,0.9*dur);
                            env = EnvGen.kr(env, t_gate, doneAction:done);
                            sig = sig * env * amp;
                            sig = Pan2.ar(sig, 0);
                        Out.ar(0, sig)
                        }).add;
)

a = Synth.new(\nosust, [\done, 0]);    // Create the Synth

a.set(\amp, 0.5, \t_gate,1);
a.set(\amp, 0.5, \done, 2, \t_gate,1);