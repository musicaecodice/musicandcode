// ====================================
// =========================> CHAPTER 3
// ====================================

// -------------------------> Init
(
s.boot;
s.meter;
s.scope;
s.freqscope;
s.plotTree;
)

// -------------------------> 3.3.1 Load one soundfile in Buffer

b = Buffer.read(s, ExampleFiles.child);

b.normalize;
b.plot;
b.play;
b.free;     // one specific Buffer
s.freeAll;  // all Buffers

// -------------------------> Load soundfiles from a folder in a Buffers Array

~paths = ("/absolute/path/to/folder" ++ "/*.wav").pathMatch;
~bufs  = ~paths.collect{arg i; Buffer.read(s, i)};

~bufs[0].play;

// -------------------------> 3.3.2 Sampling
(
SynthDef(\smp, {arg buf=0, pos=0, dur=0.2, amp=0, trsp=0, dir=1, pan=0,
                    t_gate=0,done=2;
                var sig, env;
                    sig = PlayBuf.ar(1, buf,
                                     BufRateScale.kr(buf)*trsp.midiratio*dir,
                                     t_gate,
		          BufSampleRate.kr(buf)* pos); // Absolute start position (frames)
	         // BufFrames.kr(buf) * pos);    // Relative start position (0 to 1)
                    env = Env.linen(0.01,dur-0.02,0.01);
                    env = EnvGen.kr(env, t_gate, doneAction:done);
                    sig = Pan2.ar(sig * env * amp, pan);
                Out.ar(0,sig)
                }).add;
)

Buffer.freeAll;
b = Buffer.read(s, ExampleFiles.child);

(
Synth(\smp,[\buf, b,
            \pos, 2.3,
            \dur, 0.2,
            \amp, 1,
            \trsp, 0,
            \dir, 1,
            \pan, 0,
            \done, 2,
            \t_gate, 1]);
)
// -------------------------> Deterministic sequencing
(
~tstr = 0.5; // Time stratching factor
~pos = [0.82, 3.11, 2.76, 1.39, 4.11, 2.85, 1.31, 3.05];
~amp = [0.40, 0.65, 0.85, 1.00, 0.70, 0.50, 0.30, 0.10];
~dur = [1.40, 0.46, 1.18, 2.39, 0.69, 1.15, 3.41, 1.55]* ~tstr;
~trs = [1.40, 0.46, 2.18,-2.39, 3.69, 2.15,-3.41, 1.55];
~del = [1.48, 0.54, 2.41, 1.26, 3.07, 0.89, 1.16, 0.89]* ~tstr;
~dir = [1,      -1,   -1,    1,    1,   -1,    1,   1 ];
~pan = [-1,   -0.8, -0.6, -0.4,    0,  0.4,  0.6,   1 ];
~evt = ~del.size.postln; // Number of sonic events (notes)

r = Routine({ ~evt.do({arg id;
                         Synth(\smp,[\buf,b,
                                     \pos, ~pos[id], // index call
                                     \amp, ~amp[id],
                                     \dur, ~dur[id],
                                     \trsp,~trs[id],
                                     \dir,~dir[id],
                                     \pan,~pan[id],
                                     \done,2,
                                     \t_gate,1]);
		                 ~del[id].wait })
             }).play;
)

// -------------------------> Deterministic rules
(
~nfrag = 80;                // choose a number of cues
~dur   = b.duration/~nfrag; // compute fragment duration
~pos   = 0;                 // start position
~stch  = -0.05; // if > 0 = rest elif < 0 = superimposion (poliphony)

r = Routine({
            ~nfrag.do({
                    Synth(\smp,[\buf,b,
                                \pos, ~pos.postln,
                                \dur, ~dur,
                                \amp, 1, \trsp, 0, \dir, 1, \pan, 0,
                                \done, 2, \t_gate, 1 ]);
                    ~pos = ~pos+~dur; // position increases at each step
                    (~dur+~stch).wait
	                })
            }).play;
)
// -------------------------> Enveloping
(
SynthDef(\grain, {arg buf=0, pos=0, dur=0.2, amp=0, trsp=0, dir=1, pan=0,
	                  t_gate=0, atk=0.1, done=2;
                  var sig,env;
                      sig = PlayBuf.ar(1, buf,
                               BufRateScale.kr(buf) * trsp.midiratio * dir,
                               t_gate,
                               BufSampleRate.kr(buf)* pos );
                     env = Env.perc(atk, dur-atk);
                     env = EnvGen.kr(env,t_gate,doneAction:done);
                     sig = Pan2.ar(sig * env * amp, pan);
                Out.ar(0,sig)
                }).add;
)
(
~durs = [0.79,0.68,0.57,0.46,0.25,0.14,0.23,0.32,0.41];
~pos  = [1.1,2.3,0.5,3.7,1.9,2.1,0.3,3.5,2.7];
~atk  = [0.01,0.02,0.43,0.04,0.35,0.06,0.57,0.08,0.89];

r = Routine({
            inf.do({arg item,id;
                        Synth(\grain, [\buf, b, \amp, 1,
                                       \pos, ~pos.foldAt(id), // foldAt()
                                       \done,2,
                                       \atk, ~atk.foldAt(id),
                                       \t_gate, 1]);
		                ~durs.foldAt(id).wait})
            }).reset.play
)
// -------------------------> Dynamic Envelopes
(
SynthDef(\envi,{arg buf=0,pos=0,amp=0,trsp=0,dir=1,pan=0,t_gate=0,done=2;
                var sig,env;
                    sig  = PlayBuf.ar(1,buf,
                             BufRateScale.kr(buf) * trsp.midiratio * dir,
                             t_gate,
                             BufSampleRate.kr(buf)* pos );
                    env = Env.newClear(4); // New Envelope with 4 nodes
                    env = \env.kr(env.asArray); // read from argument
                    env = EnvGen.kr(env, t_gate, doneAction:done);
                    sig = Pan2.ar(sig * env * amp, pan);
                Out.ar(0,sig)
                }).add;
)
(
d = 0.2;                           // Duration
f = [Env.perc(0.1,1).duration_(d), // Different types of envelopes
     Env.triangle(d),              // (all same duration)
     Env.sine(d),
     Env.linen(0.1,1,0.7).duration_(d)
     ];

~env = [f[0],f[1],f[2],f[3],f[2],f[4],f[1],f[2],f[0],f[2],f[3],f[1]];

r = Routine({
          inf.do({arg id;
                      Synth(\envi,[\buf,b, \amp,1, \pos,1, \done,2,
                                   \env, f.wrapAt(id), // wrapAt()
                                   \t_gate, 1]);
		            d.wait;
	               })
          }).reset.play;
)
// -------------------------> 3.3.3 Scratching
(
SynthDef(\ksig,{arg type=0, range=#[0,1], freq=1, busOut=0;
                var sig;
	                sig = Select.kr(type,
                                [MouseX.kr(range[0], range[1]),
                                 MouseY.kr(range[0], range[1]),
                                 LFNoise1.kr(freq).range(range[0], range[1])
                                ]);
	            Out.kr(busOut,sig)
        }).add;

x = Bus.control(s, 1);   // a control bus (server, n_canali)

SynthDef(\sch, {arg buf=0, busOut=0, smooth=0.02, amp=0, pos=0, pan=0;
                var pnt, sig;
                    pnt = Lag.kr(pos.linlin(0,1,0,BufFrames.kr(buf)),smooth);
                    sig = BufRd.ar(1, buf, K2A.ar(pnt));
                    sig = LeakDC.ar(sig);
                    sig = Pan2.ar(sig * amp, pan);
                    Out.ar(busOut, sig)
                }).add;
)
(
Buffer.freeAll;
b = Buffer.read(s, ExampleFiles.child);

k = Synth(\ksig, [\type,0, \range, [0, 1], \busOut, x]);   // Synth per ksig
a = Synth(\sch,  [\buf,b, \amp,1, \pos, x.asMap, \smooth,0.02, \pan,0]);
)

a.set(\smooth,0.2);
p.set(\type, 2, \freq, 2);
a.free; k.free;

// -------------------------> 3.3.4 Structures
// Record sound files

s.prepareForRecord("/absolute/path/to/prova.wav", 2); // path, channels
(
s.record;
a = Synth(\ksig, [\buf,b, \amp,1, \pan,0, \freq, 3, \gate, 1])
)
(
r = Routine({
            a.set(\fOut, 2, \gate,0); // Trig fade out
            3.wait;                   // Wait for fadeout end
            s.stopRecording;          // Stop recording
            }).play;
)
// -------------------------> Scoring
(
SynthDef(\grain, {arg buf=0, pos=0, dur=0.2, amp=0, trsp=0, dir=1,
                      pan=0, t_gate=0, atk=0.1, done=2;
                  var sig,env;
                      sig = PlayBuf.ar(1, buf,
                            BufRateScale.kr(buf) * trsp.midiratio
                                                 * dir,
                            t_gate,
                            BufSampleRate.kr(buf)* pos );
                      env = Env.perc(atk, dur-atk);
                      env = EnvGen.kr(env,t_gate,doneAction:done);
                      sig = Pan2.ar(sig * env * amp, pan);
                Out.ar(0,sig)
                }).add;

SynthDef(\ksig,{arg buf=0, amp=0,frq=0.1,fIn=0.2,fOut=0.2,pan=0,
                    gate=0,done=2;
                var punta,sig,fade;
                    punta = LFCub.ar(frq).range(0,BufFrames.kr(buf));
                    sig   = BufRd.ar(1, buf, K2A.ar(punta));
                    fade  = Linen.kr(gate,fIn,1,fOut,done);
                    sig   = Pan2.ar(sig*amp.lag(0.2)*fade,pan);
                Out.ar(0, sig);
        }).add;
)
(
Buffer.freeAll;
b = Buffer.read(s, ExampleFiles.child);
// musical objects
~durs = [0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1];
~pos  = [0.1,0.3,0.5,0.7,0.9,1.1,1.3,1.5,1.7];
~atk  = [0.01,0.02,0.43,0.04,0.35,0.06,0.57,0.08,0.89];
~pan  = 1;
~obj1 = Routine({
                inf.do({arg id;
                        Synth(\grain, [\buf, b,
                                       \amp, 0.4,
                                       \pos, ~pos.foldAt(id),
                                       \done, 2,
                                       \atk, ~atk.foldAt(id),
                                       \t_gate, 1]);
		                    ~durs.foldAt(id).wait;
                        });
                });

~amps = [0.01, 0.4, 0.1, 0.6];
~pos  = [0.5, 1.4, 3.1, 2.6, 0.5, 2.8];
~obj2 = Routine({
                inf.do({arg id;
                        ~pan = ~pan * -1;        // flip flop
                        Synth(\grain, [\buf, b,
                                       \amp, ~amps.foldAt(id),
                                       \dur, 0.2,
                                       \pos, ~amps.wrapAt(id),
                                       \done, 2,
                                       \atk, 0.01,
                                       \pan, ~pan,
                                       \t_gate, 1]);
		                0.3.wait;
                        });
                });
)
// score
(
~score = Routine({
                  2.do({                    // Ritornello (loop)
                        ~obj2.reset.play(t);         // 0 Start obj2
                        3.wait;
                        3.do({                       // 3 Ritornello
                              ~obj1.reset.play(t);   // Start obj1
                              4.wait;
                              ~obj1.stop;            // Stop obj1
                              1.wait});
                        ~obj3 = Synth(\ksig,[\buf,b, // 18 Start obj3
                                             \amp,0.1,
                                             \fIn,3,
                                             \frq,2,
                                             \gate,1]);
                        2.wait;
                        ~obj2.stop;                // 20 Stop obj1
                        1.wait;
                        ~obj1.reset.play(t);       // 21 Start obj2
                        ~obj3.set(\fOut, 4, \gate, 0); // Fout obj3
                        3.wait;
                        ~obj1.stop;                // Stop obj1
                        1.wait;                    // 25 End obj2
                        })
                })
)
// performance
~bpm = 100;
t    = TempoClock.new(~bpm/60); // Set bpm tempo

~score.reset.play(t);








