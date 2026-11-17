require 'spec_helper'
require 'tmpdir'

module RCoreMidi
  RSpec.describe 'CoreMIDI driver' do
    let(:iac_driver) { Device.all.detect { |device| device.name == 'IAC Driver' } }
    let(:bus) { iac_driver.entities.detect { |entity| entity.name == 'Bus 1' } }

    describe Device do
      describe '.all' do
        it 'describes the IAC driver' do
          expect(iac_driver).to have_attributes(uid: an_instance_of(Integer), manufacturer: 'Apple Inc.', offline: false)
        end

        it 'links entities back to their device' do
          expect(bus.device).to be(iac_driver)
        end

        it 'lists the bus endpoints' do
          expect(bus.endpoints).to contain_exactly(an_instance_of(Source), an_instance_of(Destination))
        end

        context 'when the MIDI setup does not change' do
          before do
            Device.all
            sleep 0.3
            Device.all
          end

          it 'reuses the cached device list' do
            expect(Device.all).to be(Device.all)
          end
        end

        context 'when another process adds a MIDI endpoint' do
          let(:helper_source) { File.expand_path('../../fixtures/virtual_source.c', __dir__) }
          let(:helper) { File.join(Dir.tmpdir, 'rcoremidi_virtual_source') }

          before do
            skip 'clang is not available' unless system('which clang > /dev/null 2>&1')
            system('clang', '-o', helper, helper_source, '-framework', 'CoreMIDI', '-framework', 'CoreFoundation',
                   exception: true)
            Device.all
            sleep 0.3
          end

          def device_list_after_change(cached, timeout: 5)
            deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
            loop do
              devices = Device.all
              return devices if !devices.equal?(cached) || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

              sleep 0.05
            end
          end

          it 'rebuilds the device list' do
            cached = Device.all
            helper_pid = spawn(helper)

            expect(device_list_after_change(cached)).not_to be(cached)
          ensure
            Process.wait(helper_pid) if helper_pid
          end
        end
      end
    end

    describe MIDIObject do
      describe '.find_by_unique_id' do
        it 'finds a device' do
          expect(MIDIObject.find_by_unique_id(iac_driver.uid)).to be_a(Device).and have_attributes(name: 'IAC Driver')
        end

        it 'finds a source' do
          source = bus.sources.first

          expect(MIDIObject.find_by_unique_id(source.uid)).to be_a(Source).and have_attributes(uid: source.uid)
        end

        it 'finds a destination' do
          destination = bus.destinations.first

          expect(MIDIObject.find_by_unique_id(destination.uid)).to be_a(Destination).and have_attributes(uid: destination.uid)
        end

        it 'raises for an unknown uid' do
          expect { MIDIObject.find_by_unique_id(0) }.to raise_error(ArgumentError, /not found/)
        end
      end
    end
  end
end
