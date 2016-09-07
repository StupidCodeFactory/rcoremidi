require 'spec_helper'

module RCoreMidi
  describe 'CoreMIDI driver' do
    describe Client do
      let(:destination) { Device.all.last.entities.first.endpoints.detect { |e| e.is_a? Destination } }
      let(:source)      { Device.all.last.entities.first.endpoints.detect { |e| e.is_a? Source } }
      let(:client)      { Client.new("ruby_client") }

      describe '#connect' do
        it 'can connect to a source' do
          expect(client.connect_to(source)).to be true
        end

      end
      describe '#send' do
        before do
          client.connect_to(source)
        end

        it 'sends midi packet' do
          expect { 10.times { client.send(destination, [34, 127]) } }.to_not raise_error
        end
      end

    end
  end
end
