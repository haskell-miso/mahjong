-----------------------------------------------------------------------------
-- | Sound effects synthesized with the Web Audio API — no audio assets.
-- 'soundInit' must run inside a user gesture (the Start button click) so
-- the AudioContext is allowed to play.
-----------------------------------------------------------------------------
module Sound
  ( soundInit
  , playSound
  ) where
-----------------------------------------------------------------------------
import           Control.Monad (when)
-----------------------------------------------------------------------------
import           Miso.FFI.QQ (js)
import           Miso.String (MisoString)
-----------------------------------------------------------------------------
-- | Build the tiny synth once and park it on @globalThis.__mj@.
soundInit :: IO ()
soundInit = [js|
  if (!globalThis.__mj) {
    var AC = window.AudioContext || window.webkitAudioContext;
    var ctx = new AC();
    var master = ctx.createGain();
    master.gain.value = 0.5;
    master.connect(ctx.destination);
    function noiseBuf(dur) {
      var n = Math.floor(ctx.sampleRate * dur);
      var b = ctx.createBuffer(1, n, ctx.sampleRate);
      var d = b.getChannelData(0);
      for (var i = 0; i < n; i++) d[i] = Math.random() * 2 - 1;
      return b;
    }
    function env(g, t0, a, peak, d) {
      g.gain.setValueAtTime(0, t0);
      g.gain.linearRampToValueAtTime(peak, t0 + a);
      g.gain.exponentialRampToValueAtTime(0.0001, t0 + a + d);
    }
    function tone(freq, type, t0, a, peak, d) {
      var o = ctx.createOscillator();
      o.type = type;
      o.frequency.value = freq;
      var g = ctx.createGain();
      env(g, t0, a, peak, d);
      o.connect(g);
      g.connect(master);
      o.start(t0);
      o.stop(t0 + a + d + 0.05);
    }
    function burst(t0, dur, f0, f1, peak) {
      var s = ctx.createBufferSource();
      s.buffer = noiseBuf(dur + 0.02);
      var f = ctx.createBiquadFilter();
      f.type = 'bandpass';
      f.frequency.setValueAtTime(f0, t0);
      f.frequency.exponentialRampToValueAtTime(Math.max(f1, 40), t0 + dur);
      f.Q.value = 1.1;
      var g = ctx.createGain();
      env(g, t0, 0.003, peak, dur);
      s.connect(f);
      f.connect(g);
      g.connect(master);
      s.start(t0);
    }
    globalThis.__mj = {
      ctx: ctx,
      play: function (name) {
        if (ctx.state === 'suspended') ctx.resume();
        var t = ctx.currentTime + 0.01;
        if (name === 'clack') {
          burst(t, 0.06, 2600, 900, 0.7);
          tone(190, 'sine', t, 0.002, 0.5, 0.09);
        } else if (name === 'match') {
          burst(t, 0.05, 2600, 900, 0.5);
          tone(659.25, 'sine', t, 0.005, 0.35, 0.25);
          tone(987.77, 'sine', t + 0.07, 0.005, 0.3, 0.35);
        } else if (name === 'deny') {
          tone(110, 'square', t, 0.004, 0.3, 0.11);
          tone(92, 'square', t + 0.07, 0.004, 0.25, 0.13);
        } else if (name === 'draw') {
          burst(t, 0.11, 700, 2400, 0.22);
        } else if (name === 'call') {
          tone(165, 'square', t, 0.005, 0.35, 0.12);
          tone(124, 'square', t + 0.09, 0.005, 0.45, 0.16);
          burst(t, 0.05, 1500, 600, 0.35);
        } else if (name === 'kan') {
          tone(95, 'square', t, 0.005, 0.5, 0.25);
          burst(t, 0.08, 900, 300, 0.5);
        } else if (name === 'deal') {
          for (var i = 0; i < 9; i++) {
            burst(t + i * 0.075, 0.045, 2200 + (i % 4) * 260, 1000, 0.28);
          }
        } else if (name === 'win') {
          var ns = [523.25, 659.25, 783.99, 1046.5, 1318.5];
          for (var j = 0; j < ns.length; j++) {
            tone(ns[j], 'sine', t + j * 0.11, 0.01, 0.45, 0.7);
            tone(ns[j] * 2, 'sine', t + j * 0.11, 0.01, 0.1, 0.5);
          }
          tone(261.63, 'triangle', t, 0.02, 0.22, 1.6);
        } else if (name === 'lose') {
          tone(220, 'sine', t, 0.01, 0.35, 0.5);
          tone(174.6, 'sine', t + 0.24, 0.01, 0.35, 0.8);
        }
      }
    };
  }
|]
-----------------------------------------------------------------------------
-- | Play a named effect (respecting the model's sound toggle).
playSound :: Bool -> MisoString -> IO ()
playSound enabled name = when enabled
  [js| if (globalThis.__mj) { globalThis.__mj.play(${name}); } |]
