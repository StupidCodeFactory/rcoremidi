# MIDI Message Flow Diagram

This diagram illustrates how MIDI messages flow through the RCoreMidi system, from hardware through the C extension to Ruby code.

```
┌────────────────────┐                                     ┌─────────────────────┐
│                    │                                     │                     │
│   MIDI Hardware    │                                     │    Ruby Runtime     │
│                    │                                     │                     │
└─────────┬──────────┘                                     └─────────┬───────────┘
          │                                                          │
          │ MIDI Messages                                            │
          ▼                                                          │
┌─────────────────────┐                                              │
│                     │                                              │
│  CoreMIDI Framework │                                              │
│                     │                                              │
└─────────┬───────────┘                                              │
          │                                                          │
          │ MIDIPacketList                                           │
          ▼                                                          │
┌─────────────────────────────────────────────────────────┐          │
│                                                         │          │
│                   C Extension Thread                    │          │
│                                                         │          │
│  ┌─────────────────────────────────────────────┐        │          │
│  │                                             │        │          │
│  │            MidiReadProc callback            │        │          │
│  │                                             │        │          │
│  │  1. Gets MIDI packet                        │        │          │
│  │  2. Extracts MIDI events (START/STOP/TICK)  │        │          │
│  │  3. Updates transport state                 │        │          │
│  │  4. Packages transport data                 │        │          │
│  │                                             │        │          │
│  └──────────────────┬──────────────────────────┘        │          │
│                     │                                   │          │
│                     │ CFData (transport state)          │          │
│                     ▼                                   │          │
│  ┌─────────────────────────────────────────────┐        │          │
│  │                                             │        │          │
│  │         CFMessagePortSendRequest            │        │          │
│  │                                             │        │          │
│  └──────────────────┬──────────────────────────┘        │          │
│                     │                                   │          │
└─────────────────────┼───────────────────────────────────┘          │
                      │                                              │
                      │ Message with transport data                  │
                      ▼                                              │
┌─────────────────────────────────────────────────────────┐          │
│                                                         │          │
│                    Main Thread                          │          │
│                                                         │          │
│  ┌─────────────────────────────────────────────┐        │          │
│  │                                             │        │          │
│  │      MIDIClockSynchronisation callback      │        │          │
│  │                                             │        │          │
│  │  1. Receives transport data from message    │        │          │
│  │  2. Calls Ruby methods with GVL held        │        │          │
│  │                                             │        │          │
│  └──────────────────┬──────────────────────────┘        │          │
│                     │                                   │          │
│                     │ Ruby method calls                 │          │
│                     │                                   │          │
└─────────────────────┼───────────────────────────────────┘          │
                      │                                              │
                      │                                              │
                      ▼                                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│                         Ruby Application Code                        │
│                                                                      │
│  ┌────────────────────────────┐     ┌───────────────────────────┐    │
│  │                            │     │                           │    │
│  │     Client#on_start        │     │     Client#on_tick        │    │
│  │                            │     │                           │    │
│  │ - Called for START message │     │ - Called for TICK message │    │
│  │                            │     │ - Updates bar counter     │    │
│  │                            │     │ - Calls live.generate_beats│    │
│  │                            │     │ - Sends MIDI via send_packets│  │
│  │                            │     │                           │    │
│  └────────────────────────────┘     └───────────────────────────┘    │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                                │  │
│  │                      Live#generate_beats                       │  │
│  │                                                                │  │
│  │ - Iterates through all instruments                            │  │
│  │ - Calls Instrument#generate_bar on each                       │  │
│  │ - Returns generated notes for current bar                     │  │
│  │                                                               │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## Message Flow Explanation

1. **MIDI Hardware to CoreMIDI**:
   - MIDI hardware sends messages (START, STOP, TICK, etc.)
   - CoreMIDI framework receives these and packages them as `MIDIPacketList`

2. **CoreMIDI to C Extension**:
   - CoreMIDI calls `MidiReadProc` callback with the packet list
   - This happens in a separate thread from the Ruby runtime
   - `MidiReadProc` parses MIDI messages and updates transport state (bar, beat, etc.)

3. **C Extension to Main Thread via CFMessagePort**:
   - `MidiReadProc` creates a copy of the transport state 
   - It sends this data via `CFMessagePortSendRequest` to the main thread
   - This cross-thread communication avoids direct Ruby calls from the MIDI thread

4. **Main Thread to Ruby**:
   - `MIDIClockSynchronisation` function receives the message in the main thread
   - It calls appropriate Ruby methods (`on_start`, `on_tick`) with the transport data
   - These calls are safe because they happen in the main thread with GVL held

5. **Ruby Processing**:
   - `Client#on_tick` updates the bar counter based on tick count
   - It calls `Live#generate_beats` to get notes for the current bar
   - Generated notes are sent back to MIDI hardware via `send_packets`

## Key Components

- **MidiReadProc**: C callback that receives MIDI messages from hardware
- **CFMessagePort**: macOS IPC mechanism for thread-safe communication
- **MIDIClockSynchronisation**: C callback for processing messages in main thread
- **Client#on_tick**: Ruby method that processes each clock tick
- **Live#generate_beats**: Ruby method that generates MIDI notes based on current bar

This architecture separates real-time MIDI processing from Ruby execution, addressing issues with thread safety, timing precision, and synchronization.