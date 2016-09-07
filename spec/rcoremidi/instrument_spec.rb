require 'spec_helper'

RSpec.describe RCoreMidi::Instrument do

  subject { described_class.new(:instrument_name, 0) }

  it_behaves_like 'registrable', [:instrument_name, :midi_channel]

  describe '#play'  do
    let(:bar)   { 1 }
    let(:clip)  { double(RCoreMidi::Clip) }
    let(:track) { {} }

    it 'adds a clip to the instrument track' do
      expect(subject).to receive(:track).and_return(track)

      subject.play(bar, clip)

      expect(track).to eq(1 => clip)
    end
  end
end
