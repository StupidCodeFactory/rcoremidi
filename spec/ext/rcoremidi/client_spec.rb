require 'spec_helper'
require 'timeout'

module RCoreMidi
  RSpec.describe 'CoreMIDI driver' do
    describe Client do
      let(:device)      { Device.all.detect { |d| d.name == 'IAC Driver' } }
      let(:entity)      { device.entities.detect { |e| e.name == 'Bus 1' } }
      let(:destination) { entity.endpoints.detect { |e| e.is_a? Destination } }
      let(:source)      { entity.endpoints.detect { |e| e.is_a? Source } }
      let(:client)      { Client.new('ruby_client') }
      let(:midi_event)  { Struct.new(:on, :on_timestamp, :off, :off_timestamp) }
      let(:one_millisecond) { 1_000_000 }
      let(:clock_start_then_tick) { midi_event.new([0xFA], 0, [0xF8], one_millisecond) }
      let(:clock_stop) { midi_event.new([0xFC], 2 * one_millisecond, [0xF8], 3 * one_millisecond) }
      let(:events) { Queue.new }

      after { client.dispose }

      def next_events(count)
        Array.new(count) { events.pop(timeout: 2) }
      end

      def start_clock_thread
        runner = Thread.new { client.start }
        Timeout.timeout(2) { Thread.pass until client.running? || !runner.alive? }
        runner
      end

      def run_clock
        runner = start_clock_thread
        yield runner
      ensure
        client.stop
        runner.join(2)
      end

      it 'rejects a client name that is not valid UTF-8' do
        expect { Client.new("bad\xFFname".b) }.to raise_error(ArgumentError, /UTF-8/)
      end

      describe '#connect_to' do
        it 'can connect to a source' do
          expect(client.connect_to(source)).to be true
        end
      end

      describe '#send_packets' do
        before { client.connect_to(source) }

        it 'sends the note on and note off packets' do
          expect { client.send_packets(destination, [Note.new('C3', 0, 0, 0)]) }.not_to raise_error
        end

        it 'schedules from a given host time' do
          expect { client.send_packets(destination, [Note.new('C3', 0, 0, 0)], 0) }.not_to raise_error
        end

        it 'rejects a MIDI message longer than a packet can hold' do
          oversized = midi_event.new([0x90] * 257, 0, [0x80, 60, 0], 0)

          expect { client.send_packets(destination, [oversized]) }.to raise_error(ArgumentError, /too long/)
        end

        it 'rejects bytes outside 0..255' do
          event = midi_event.new([0x90, -1, 90], 0, [0x80, 60, 0], 0)

          expect { client.send_packets(destination, [event]) }.to raise_error(ArgumentError, /out of range/)
        end

        it 'rejects a message that does not start with a status byte' do
          event = midi_event.new([60, 90], 0, [0x80, 60, 0], 0)

          expect { client.send_packets(destination, [event]) }.to raise_error(ArgumentError, /status byte/)
        end

        it 'rejects negative timestamps' do
          event = midi_event.new([0x90, 60, 90], -1, [0x80, 60, 0], 0)

          expect { client.send_packets(destination, [event]) }.to raise_error(ArgumentError, /timestamp/)
        end
      end

      describe '#start' do
        before do
          received = events
          client.define_singleton_method(:on_start) { |host_time| received << [:start, host_time.class] }
          client.define_singleton_method(:on_tick) { |tick, host_time| received << [tick, host_time.class] }
          client.define_singleton_method(:on_stop) { received << :stop }
          client.connect_to(source)
        end

        it 'delivers clock start and the first tick at position 0 with host times' do
          run_clock do
            client.send_packets(destination, [clock_start_then_tick])

            expect(next_events(2)).to eq([[:start, Integer], [0, Integer]])
          end
        end

        it 'delivers clock stop to an optional handler' do
          run_clock do
            client.send_packets(destination, [clock_start_then_tick, clock_stop])

            expect(next_events(4)).to include(:stop)
          end
        end

        it 'ignores clock messages received before it started' do
          client.send_packets(destination, [clock_start_then_tick])
          sleep 0.05

          run_clock do
            sleep 0.05

            expect(events).to be_empty
          end
        end

        it 'keeps running after a harmless interrupt such as Thread#wakeup' do
          run_clock do |runner|
            runner.wakeup
            sleep 0.05
            client.send_packets(destination, [clock_start_then_tick])

            expect(next_events(2)).to eq([[:start, Integer], [0, Integer]])
          end
        end

        it 'keeps delivering after the client object is moved by GC compaction' do
          skip 'GC compaction unsupported' unless GC.respond_to?(:compact)
          holder = [client]

          run_clock do
            GC.compact
            client.send_packets(destination, [clock_start_then_tick])

            expect(next_events(2)).to eq([[:start, Integer], [0, Integer]])
          end
          expect(holder.first).to be(client)
        end

        it 'returns once stopped from another thread' do
          runner = start_clock_thread
          client.stop

          expect(runner.join(2)).to be(runner)
        end

        it 'raises errors from the Ruby clock handlers in the starting thread' do
          client.define_singleton_method(:on_start) { |_host_time| raise ArgumentError, 'bad clip' }
          runner = start_clock_thread
          runner.report_on_exception = false
          client.send_packets(destination, [clock_start_then_tick])

          expect { runner.join(2) }.to raise_error(ArgumentError, 'bad clip')
        end

        it 'can start again after a handler error' do
          client.define_singleton_method(:on_start) { |_host_time| raise ArgumentError, 'bad clip' }
          runner = start_clock_thread
          runner.report_on_exception = false
          client.send_packets(destination, [clock_start_then_tick])
          expect { runner.join(2) }.to raise_error(ArgumentError)

          received = events
          client.define_singleton_method(:on_start) { |host_time| received << [:start, host_time.class] }
          run_clock do
            client.send_packets(destination, [clock_start_then_tick])

            expect(next_events(2)).to eq([[:start, Integer], [0, Integer]])
          end
        end

        it 'refuses to start twice' do
          run_clock do
            expect { client.start }.to raise_error(RuntimeError, /already started/)
          end
        end

        it 'stops when its thread is killed' do
          runner = start_clock_thread
          runner.kill

          expect(runner.join(2)).to be(runner)
        end
      end

      describe '#dispose' do
        let(:clock_flood) do
          Array.new(48) { |i| midi_event.new([0xF8], i * one_millisecond, [0xF8], (i * one_millisecond) + 500_000) }
        end

        def start_listener
          listener = Client.new('disposed listener')
          listener.define_singleton_method(:on_start) { |_host_time| nil }
          listener.define_singleton_method(:on_tick) { |_tick, _host_time| nil }
          listener.connect_to(source)
          [listener, Thread.new { listener.start }]
        end

        it 'stops a running clock and survives clock messages still in flight' do
          runners = Array.new(20) do
            listener, runner = start_listener
            client.send_packets(destination, clock_flood)
            sleep 0.005
            listener.dispose
            runner
          end
          GC.start
          sleep 1.5

          expect(runners.map { |runner| runner.join(2) }).to all(be_a(Thread))
        end
      end
    end
  end
end
