# Clock lab

Checks that notes sent by `RCoreMidi::Client` land on the MIDI clock that drives them. Everything goes through IAC Driver Bus 1: the clock master sends clock there, the test app (`clock_check`) listens to it and plays back to it, and `midi_monitor` records every message with its timestamp.

The test app plays a kick (note 37) on every beat and adds a snare (note 38) on each downbeat. In Ultrabeat, those are the Kick and Snare voices.

## Simulated clock

```bash
script/clock_lab/run simulated
```

`clock_master` plays Start, 8 bars at 120 bpm, 8 bars at 90 bpm, Stop, a 2 s pause, Continue, 4 bars and Stop. Pass two tempos to change them: `script/clock_lab/run simulated 140 70`. Keep your DAW stopped meanwhile; it shares the bus.

## DAW clock

```bash
script/clock_lab/run daw
```

Set the DAW to send MIDI clock to IAC Driver Bus 1 and to stay on its internal clock. Point a drum track at Bus 1, channel 1. Play, stop, continue and change the tempo, then press Ctrl-C to stop the app and analyse the recording. To analyse a recording again: `script/clock_lab/run analyze tmp/clock_lab/daw.log`.

In Logic Pro: Settings > MIDI > Inputs, enable IAC Driver Bus 1. File > Project Settings > Synchronization: General, Sync Mode Internal. MIDI, destination IAC Driver with Clock ticked.

## Reading the analysis

Each row is one bar of one pass. A pass starts at every Start or Song Position. The worst offset is the largest gap between a note and the clock tick it belongs to. "Notes outside the clock" counts notes with no clock around them, such as downbeats sent just before a Stop that landed on a bar line. "Notes still sounding" must be 0.

Recordings and binaries go to `tmp/clock_lab`. `clock_check/config/connections.yml` holds the unique IDs of this machine's IAC Bus 1 endpoints; on another machine, list them by running `bin/arcx connections` inside `clock_check` and update it.
