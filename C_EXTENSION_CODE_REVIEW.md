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
| Real-time | Notes scheduled from "Ruby noticed the tick", so every downbeat was late | Ticks carry the packet host time. The next bar is scheduled one beat ahead at its projected downbeat |
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

## Verification

- Driver specs (`spec/ext`) cover tick delivery, stop, `Thread#kill`, `Thread#wakeup`, handler errors and restart, GC compaction, validation and device lookups. They passed on 18 seeds. One run failed for every example at process start because `MIDIClientCreate` returned OSStatus -304 (MIDI server unavailable). The same seed passed on 3 reruns.
- Reproduction scripts for compaction (client moved, still delivered), a trapped USR1 signal (clock kept running), Ctrl-C (`Interrupt` after 0.51 s) and a slow 50 ms handler (82 of 82 events, 0 dropped).
- Soak test: 40,000 lookups, 10,000 sends of 16 notes and 250 client create/dispose cycles with flat RSS.

## Known limits

- Note offsets inside a bar come from the configured bpm (`DurationCalculator`), not the incoming clock, so they drift if the master's tempo differs from `Application.config.bpm`. Bar downbeats follow the clock.
- Bar 1 is anchored to the Start message time, not the first clock after it.
- `MIDIInputPortCreate`, `MIDISend` and `MIDIPacketList` are marked to-be-deprecated in favour of `MIDIEventList` (MIDI 2.0 UMP). They still work without warnings.
- Whether `MIDIPortDispose` waits for an in-flight read proc is not documented. Ports are disposed before the node is freed, which is the safest order the API allows.
- `Device.all` is cached for the life of the process and does not see hot-plugged devices.
