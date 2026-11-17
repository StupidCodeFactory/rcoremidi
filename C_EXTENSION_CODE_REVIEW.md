# RCoreMidi C Extension Review

Review of `ext/rcoremidi` for memory safety, CRuby VM integration and real-time MIDI behaviour. It replaces the April 2025 review, whose findings are all resolved below.

## Design

See `MIDI_FLOW_DIAGRAM.md`. The CFMessagePort and CFRunLoop hand-off from the 2023 driver has been replaced by a lock-free ring buffer plus a dispatch semaphore, for these reasons:

- A message port queues only about 5 messages and silently dropped ticks and Start messages once Ruby fell behind.
- Ruby was called from inside a CoreFoundation callout. An interrupt arriving at the wrong moment unwound a Ruby exception through CFRunLoop frames, leaving a dangling pointer to a dead stack frame.
- Every MIDI packet allocated CF objects on the CoreMIDI real-time thread.
- The port name was registered system-wide, so any process could inject clock messages.

## Findings resolved

| Area | Problem | Resolution |
| --- | --- | --- |
| GC | `rb_client_obj` stored in the C struct without a mark or compact hook: segfault after `GC.compact` | No VALUE is stored. Handlers use `self` from the `start` stack frame |
| VM | Ruby exceptions could unwind through CoreFoundation frames | Ruby is called only from `start`'s own frames; `rb_ensure` resets state |
| VM | Any interrupt, including a trapped signal or `Thread#wakeup`, stopped the clock | The unblock function only wakes the waiter. Only `stop`/`dispose` stop it; `rb_thread_check_ints` runs traps |
| VM | A custom `SIGINT` handler replaced Ruby's | Removed; Ctrl-C raises `Interrupt` normally |
| Real-time | Ticks dropped at about 5 queued messages; stale ticks replayed on start | 1024-event ring buffer; events ignored while not running; drops counted |
| Real-time | Allocation, locks and stdio on the CoreMIDI thread | Read proc only writes the ring buffer and signals a semaphore |
| Real-time | Notes scheduled from "Ruby noticed the tick", so every downbeat was late | Ticks carry the packet host time. Each note is sent 3 ticks before its clock position, timed from the latest clock |
| Real-time | `qsort` could put note-on before note-off at equal timestamps, cutting repeated notes | Stable `mergesort`; note-off sorts before note-on at equal timestamps |
| Real-time | Note-off timestamps were not converted to host time | Both converted with `AudioConvertNanosToHostTime` |
| Real-time | Scheduled notes kept playing or hung after stop/dispose | `MIDIFlushOutput` plus All Sound Off and All Notes Off |
| Clock | First F8 after Start counted as tick 1; SPP not masked; Stop/Continue ignored | Start ⇒ tick 0 on the next F8; SPP masked and applied to the next clock; Stop/Continue forwarded |
| Memory | `midi_object_alloc` leaked a `malloc` per object | Removed |
| Memory | Property dictionaries and strings from CoreMIDI never released | Direct property getters; every `Copy` result released |
| Memory | `send_packets` leaked its packet list and byte buffers, including when Ruby raised | `ALLOCV` buffers reclaimed by GC |
| Lifetime | GC freed the node while CoreMIDI could still call the read proc | Ports disposed before the node is freed |
| Lifetime | `MIDIClientDispose` per client can stop the MIDI server (SDK warning) | One process-wide MIDI client that is never disposed; each Ruby client owns two ports |
| Safety | Invalid UTF-8 client name aborted the process | Raises `ArgumentError` |
| Safety | Bytes and timestamps not range-checked (-1 became System Reset) | Bytes 0..255, status byte first, timestamps 0..1 hour |
| Safety | NULL dereference for devices without a `protocol` property; `@receives_notes` uninitialised; "supports MMC" read the wrong key | Fixed |
| Safety | Objective-C helper returned a pointer into an autoreleased buffer | Removed; pure CoreFoundation conversion |
| Timing | Note offsets inside a bar came from the configured bpm, so they drifted when the master's tempo differed | Note offsets are converted to clock positions and timed with the measured tick period |
| Timing | A whole bar was timed one beat ahead, so a tempo change put the next bar off by up to 330 ms (Logic: 120 to 94 bpm) | Each note is timed 3 ticks ahead from the latest clock. The 120 to 90 bpm simulated jump is now within 0.05 ms |
| Timing | A tempo changed while stopped was ignored for the first bar after Continue (Logic: up to 320 ms off) | The measured tempo is forgotten on Stop and re-measured from the first clocks after Continue |
| Timing | Logic follows Continue with a burst of 4–6 clocks a fraction of a microsecond apart, then a shortened gap. Those intervals read as an absurdly fast tempo, so notes fired at once (Logic: up to 100 ms early) with the note-off almost at the same instant | An interval counts only when it and the previous interval are both at least 2 ms (`MINIMUM_CLOCK_INTERVAL_NANOSECONDS`, about 1250 bpm) |
| Timing | Bar 1 was anchored to the Start message, not to the first clock after it | Bar 1 is generated on Start and its downbeat sent on the first clock (tick 0), anchored to that clock's timestamp |
| Timing | Continue waited for the next bar: every Logic cycle loop dropped bar 1, and Continue partway through a bar left the rest of it silent. The Stop–Continue pause also counted as a tick interval | Continue plays the rest of the current bar from the resume point; the last tick is forgotten on Stop |
| API | `MIDIInputPortCreate`, `MIDISend` and `MIDIPacketList` are to-be-deprecated | Input uses `MIDIInputPortCreateWithProtocol` with a receive block; output uses `MIDIEventList` and `MIDISendEventList`. MIDI 1.0 bytes are converted to Universal MIDI Packets (`RCoreMidi::UniversalPacket.words_for`), including multi-packet SysEx |
| Lifetime | Whether `MIDIPortDispose` waits for an in-flight read was undocumented | The clock state lives outside the Ruby object. It is freed one second after the port is disposed, and only once no receive call is in progress |
| Devices | `Device.all` was cached for the life of the process | The shared MIDI client runs on its own run-loop thread so CoreMIDI can deliver setup notifications. Any setup or property change rebuilds the list on the next call |

## Verification

- Ruby 4.0.9: the full suite (96 examples) passes on 6 seeds.
- Driver specs (`spec/ext`) cover:
  - tick delivery, stop, `Thread#kill`, `Thread#wakeup`, handler errors and restart, and GC compaction;
  - validation, the UMP encoding (channel voice, system, SysEx, invalid input) and device lookups;
  - `Device.all` rebuilding after another process adds a virtual source;
  - disposing 20 running clients while clock messages are still arriving.
- One earlier run failed for every example at process start because `MIDIClientCreate` returned OSStatus -304 (MIDI server unavailable). The same seed passed on 3 reruns.
- Reproduction scripts:
  - compaction, both while running and before start: the client moved and still delivered;
  - a trapped USR1 signal: the clock kept running;
  - Ctrl-C: `Interrupt` raised after 0.51 s;
  - a slow 50 ms handler: 82 of 82 events delivered, 0 dropped.
- Soak test: 40,000 lookups, 10,000 sends of 16 notes and 250 client create/dispose cycles, with flat RSS.

## Remaining notes

- The receive block runs on CoreMIDI's high-priority thread and only writes the ring buffer, so the one-second deferred release covers any in-flight call by a wide margin. A receive call that stays blocked for more than a second keeps postponing the release until it finishes.
- Until two consecutive clocks have been seen after Start or Continue, only notes due on the current clock are sent.
- After Continue, notes of the current bar that fall before the resume point are skipped, not played late.
- When Stop lands exactly on a bar line, that bar's downbeat notes have already been sent; All Notes Off cuts them within 1 ms.
- `NOTE_LOOKAHEAD_TICKS` (3) and `TICK_PERIOD_SMOOTHING` (4) in `lib/rcoremidi/client.rb` trade tempo-change response against tolerance for Ruby pauses and clock jitter. A jittery hardware clock may need more smoothing.
- Live check against Logic Pro over the IAC bus: steady-tempo notes within 0.25 ms of the clock; clock messages delivered within 0.8 ms.
