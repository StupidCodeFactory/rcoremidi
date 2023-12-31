require 'spec_helper'

module RCoreMidi
  RSpec.describe 'CoreMIDI driver' do
    describe Client do
      let(:device)      { Device.all.detect { |d| d.name == 'IAC Driver' } }
      let(:entity)      { device.entities.detect { |e| e.name == 'Bus 1' } }
      let(:destination) { entity.endpoints.detect { |e| e.is_a? Destination } }
      let(:source)      { entity.endpoints.detect { |e| e.is_a? Source } }
      let(:client)      { Client.new('ruby_client') }

      describe '#connect' do
        it 'can connect to a source' do
          expect(client.connect_to(source)).to be true
        end
      end
      describe '#send' do
        before { client.connect_to(source) }
        let(:note) { Note.new('C3', nil, nil, 0) }

        it 'sends midi packet' do
          expect { 1.times { client.send(destination, note.on) } }.to_not raise_error
        end
      end
    end
  end
end
