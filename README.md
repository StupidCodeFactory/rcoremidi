# rcoremidi

Ruby bindings for the macOS [CoreMIDI](https://developer.apple.com/documentation/coremidi) framework, written as a C extension.

rcoremidi lists MIDI devices and their endpoints, follows an external MIDI clock (Start, Clock, Stop, Continue, Song Position) by calling hooks on a `RCoreMidi::Client` subclass, and sends timestamped notes through CoreMIDI's host-time scheduler. It is only a driver: it has no notion of bars, tempo or patterns.

For live coding music on top of it, see [archaeopteryx](https://github.com/StupidCodeFactory/archaeopteryx).

## Requirements

- macOS 11 or later (the extension links CoreMIDI, CoreAudio and CoreFoundation and uses the Universal MIDI Packet API)
- Ruby 3.2 or later
- Xcode command line tools, to compile the extension

It does not build on Linux or Windows.

## Install

```sh
gem install rcoremidi
```

or in a Gemfile:

```ruby
gem 'rcoremidi'
```

From a checkout, `bundle install && bundle exec rake compile` builds the extension into `lib/`.

## Listing devices

```ruby
require 'rcoremidi'

RCoreMidi::Device.all.each do |device|
  puts device.name
  device.entities.each do |entity|
    puts "  #{entity.name}: #{entity.sources.size} in, #{entity.destinations.size} out"
  end
end
```

`Device.all` is rebuilt after any CoreMIDI setup change. Each `Entity` has `endpoints`, split into `sources` (MIDI in) and `destinations` (MIDI out). `RCoreMidi::Destination.named('Port 1')` finds a destination by name across all devices, and raises if none or several match.

## Following a clock and sending notes

Subclass `RCoreMidi::Client` and override the hooks you need. The C extension calls them on the thread that called `start`:

- `on_start(host_time)` on MIDI Start; the next clock is tick 0
- `on_tick(tick, host_time)` on every MIDI Clock, 24 per quarter note (`Client::TICKS_PER_QUARTER`)
- `on_stop` and `on_continue`

All four are no-ops by default.

`send_packets(destination, notes, base_host_time = now)` schedules notes. Each note responds to `on`, `on_timestamp`, `off` and `off_timestamp`; `RCoreMidi::Client::TimedNote` is a Struct with exactly those members. `on` and `off` are MIDI 1.0 bytes, and the timestamps are nanoseconds after `base_host_time`.

```ruby
require 'rcoremidi'

class Metronome < RCoreMidi::Client
  CLICK = 37
  CLICK_LENGTH = 50_000_000 # nanoseconds

  def on_tick(tick, host_time)
    return unless (tick % TICKS_PER_QUARTER).zero?

    note = TimedNote.new([0x99, CLICK, 100], 0, [0x89, CLICK, 0], CLICK_LENGTH)
    send_packets(midi_out, [note], host_time)
  end

  def on_stop
    silence
  end
end

iac = RCoreMidi::Device.all.detect { |device| device.name == 'IAC Driver' }
bus = iac.entities.first

metronome = Metronome.new('metronome')
metronome.midi_in = bus.sources.first
metronome.midi_out = bus.destinations.first
metronome.connect!

begin
  metronome.start # blocks until stop or Ctrl-C; other Ruby threads keep running
ensure
  metronome.dispose
end
```

Other driver methods: `stop`, `running?`, `silence` (unschedule pending packets and send All Notes Off on all channels of every destination it has sent to), `dropped_clock_events` and `dispose`. `RCoreMidi::HostTime.now`, `.to_nanoseconds` and `.from_nanoseconds` convert CoreMIDI host times.

See [MIDI_FLOW_DIAGRAM.md](MIDI_FLOW_DIAGRAM.md) for how clock events reach Ruby and [C_EXTENSION_CODE_REVIEW.md](C_EXTENSION_CODE_REVIEW.md) for notes on the extension's design.

## Development

```sh
bundle install
bundle exec rake compile
bundle exec rspec
```

The extension specs expect the IAC Driver to be enabled in Audio MIDI Setup. `spec/rcoremidi/client_spec.rb` runs without the compiled extension.

## License

The MIT License

Copyright (c) 2010 Yann Marquet

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
