# Modular demo

Steps a Moog DFAM from rcoremidi through an LPZW Tram 8, clocked by the modular rack.

Wiring on this machine:

- The rack's MIDI clock reaches the Mac on the MOTU MIDI Express XT "Sync Port", which `config/connections.yml` uses as `midi_in`.
- The Tram 8 listens on MOTU Port 1, channel 10. Gates 1–8 answer notes C4–G4, and CV out N follows the velocity of gate N's note (127 is 5 V).
- Patch Tram 8 gate 1 into the DFAM's ADV/CLOCK and CV 1 into its VELOCITY input.

`instruments/dfam_steps.rb` sends to `output: 'Port 1'` on channel 10 (index 9). `clips/dfam_steps.rb` plays gate 1 on every other sixteenth with a rising velocity lane, so each DFAM step gets a louder velocity than the last.

Run it from this folder:

```bash
RUBYLIB=../../lib ruby bin/arcx start
```

Then press start on the rack. Edit `clips/dfam_steps.rb` while it plays: change the rhythm to choose when the DFAM steps, and the `velocity:` lane to set the CV at each step.
