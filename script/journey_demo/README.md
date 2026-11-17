# Journey demo

A small arcx project to hear a key journey. `clips/voyage.rb` walks from C major up to three steps away on the key graph and back home, four bars per key. Three clips follow it:

- `drums` (channel 1): a kick on every beat, hi-hats that get busier the farther the music is from home, a snare build in the bar before the music arrives home, and a crash when the music arrives home.
- `bass` (channel 2): the tonic of the current key, an octave higher every two steps away, and the leading tone in the two bars before home.
- `pads` (channel 3): the tonic chord, the pivot and dominant chords on the first bar of each new key, and V/V on the last bar at the farthest key.

Run it from this folder, with your DAW sending MIDI clock to IAC Driver Bus 1 and three instrument tracks listening to Bus 1 on channels 1 to 3:

```bash
RUBYLIB=../../lib ruby bin/arcx start
```

While it plays, edit `clips/voyage.rb` and save. Bars already prepared stay as they are; the journey carries on from the current key with the new options. For example `mode: :down` heads home at once, `mode: :random` wanders, and `range: -1` goes one step short of the farthest key.

`config/connections.yml` holds this machine's IAC Bus 1 endpoint IDs. On another machine, run `bin/arcx connections` here and update it.
