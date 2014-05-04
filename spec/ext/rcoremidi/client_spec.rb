require 'spec_helper'

module RCoreMidi
  describe 'CoreMIDI driver' do
    describe Client do
      let(:destination) { MIDIObject.find_by_unique_id(1912813983) }
      let(:source)      { MIDIObject.find_by_unique_id(646417791)  }
      let(:client)      { Client.new("ruby_client") }

      describe '#connect' do
        it 'can connect to a source' do
          expect(client.connect_to(source)).to be_true
        end

      end
      describe '#send' do
      end

    end
  end
end
