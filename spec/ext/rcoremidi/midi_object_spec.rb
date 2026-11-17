require 'spec_helper'

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
