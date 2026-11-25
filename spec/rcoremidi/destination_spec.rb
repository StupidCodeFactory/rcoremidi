require 'spec_helper'

RSpec.describe RCoreMidi::Destination do
  describe '.named' do
    it 'finds the destination with that name' do
      expect(described_class.named('Bus 1')).to have_attributes(class: described_class, name: 'Bus 1')
    end

    it 'refuses a name no destination has' do
      expect { described_class.named('No Such Port') }.to raise_error(ArgumentError, /No MIDI destination named "No Such Port"/)
    end

    context 'when several devices have a destination with that name' do
      let(:destination) { instance_double(described_class, name: 'Port 1') }

      def device_named(name)
        instance_double(RCoreMidi::Device, name: name,
                                           entities: [instance_double(RCoreMidi::Entity, destinations: [destination])])
      end

      before { allow(RCoreMidi::Device).to receive(:all).and_return([device_named('MOTU'), device_named('Other')]) }

      it 'refuses to guess, naming the devices' do
        expect { described_class.named('Port 1') }.to raise_error(ArgumentError, /MOTU, Other/)
      end
    end
  end
end
