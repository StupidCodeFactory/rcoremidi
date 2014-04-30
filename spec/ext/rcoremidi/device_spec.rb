require 'spec_helper'

module RCoreMidi
  describe Device do

    describe '.get_number_of_devices' do
      it 'returns the correct number of devices' do
        # granted IAC bus, Network and my MOTU... :-()
        expect(Device.get_number_of_devices).to eq(3)
      end
    end

    describe '.get_device' do
      it 'gets the first device' do
        expect(Device.get_device(1).uid).to eq(1111)
      end
    end

    describe '#initialize' do
      it 'instanciates a device'
    end
  end

end
