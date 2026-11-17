require 'spec_helper'
require 'rcoremidi/cli'

RSpec.describe RCoreMidi::Commands::Connections do
  let(:source) { double(RCoreMidi::Source, uid: 111) }
  let(:destination) { double(RCoreMidi::Destination, uid: 222) }
  let(:entity) { double(RCoreMidi::Entity, name: 'Bus 1', sources: [source], destinations: [destination]) }
  let(:device) do
    double(
      RCoreMidi::Device,
      name: 'IAC Driver', model: 'IAC', offline: false, transmits_mtc: false, receives_mtc: false,
      entities_with_midi_in: [entity], entities_with_midi_out: [entity]
    )
  end

  before { allow(RCoreMidi::Device).to receive(:all).and_return([device]) }

  it 'prints the available MIDI inputs' do
    expect { described_class.start([]) }.to output(/Available MIDI Inputs:.*IAC Driver\s+Bus 1\s+IAC\s+111\s+online/m).to_stdout
  end

  it 'prints the available MIDI outputs' do
    expect { described_class.start([]) }.to output(/Available MIDI Outputs:.*IAC Driver\s+Bus 1\s+IAC\s+222\s+online/m).to_stdout
  end
end
