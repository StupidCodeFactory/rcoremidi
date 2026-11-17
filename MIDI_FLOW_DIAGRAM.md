# MIDI Message Flow

How MIDI clock reaches Ruby, and how notes go back out, in the C extension (`ext/rcoremidi/client.c`) and `RCoreMidi::Client` (`lib/rcoremidi/client.rb`).

```
 MIDI master (DAW, drum machine)
        │  Start FA · Clock F8 · Stop FC · Continue FB · Song Position F2
        ▼
 CoreMIDI ──► receive block             CoreMIDI real-time thread
              │  reads Universal MIDI Packets (MIDI 1.0 protocol)
              │  tracks the tick position (Start ⇒ next F8 is tick 0)
              │  copies {kind, tick, packet host time} into a lock-free
              │  ring buffer (1024 events, C11 atomics, no allocation)
              │  signals a dispatch semaphore
              ▼
 Client#start  (any Ruby thread, e.g. Thread.new { client.start })
              │  waits on the semaphore with the GVL released,
              │  so every other Ruby thread keeps running
              │  re-acquires the GVL, drains the ring buffer and calls:
              │     on_start(host_time)
              │     on_tick(tick, host_time)
              │     on_stop / on_continue   (only if defined)
              │  then runs pending interrupts (traps, Ctrl-C, Thread#kill)
              ▼
 RCoreMidi::Client
              │  measures the tick period from the clock host times
              │  (forgotten on Stop, so a tempo change while stopped
              │  is picked up from the first clocks after Continue)
              │  counts an interval only when it and the previous one
              │  are at least 2 ms, so the catch-up clocks a DAW sends
              │  with Continue and the shortened gap after them are
              │  ignored
              │  on Start, generates bar 1; one beat (24 ticks) before
              │  each later bar, generates it
              │  converts each note's offset into a clock position
              │  sends each note 3 ticks before its position, timed from
              │  the latest clock and the measured tick period
              │  Continue plays the rest of the current bar from the
              │  resume point, skipping notes already in the past
              ▼
 send_packets(destination, notes, base_host_time)
              │  validates bytes and timestamps, converts MIDI 1.0 bytes
              │  to Universal MIDI Packets, sorts by time
              │  (note-off before note-on at the same instant)
              ▼
 MIDISendEventList: CoreMIDI schedules each event at its host time ──► synth
```

The shared CoreMIDI client lives on a dedicated run-loop thread, so setup notifications reach it. `Device.all` rebuilds its list after any setup change.

## Guarantees

- The CoreMIDI thread never takes a lock, allocates, prints or calls Ruby.
- Ruby code only ever runs on the thread that called `start`, with the GVL held and no CoreFoundation frames on the stack, so exceptions unwind normally.
- `start` returns when `stop` or `dispose` is called. Exceptions raised in a handler, Ctrl-C and `Thread#kill` propagate out of `start`. Signals with a trap handler and `Thread#wakeup` do not stop the clock.
- Clock messages received while the clock is not running are ignored. If Ruby falls more than 1024 events behind, new events are dropped and counted in `dropped_clock_events`.
- `on_stop` calls `silence`, which unschedules pending packets and sends All Sound Off and All Notes Off on all 16 channels of the last destination.
