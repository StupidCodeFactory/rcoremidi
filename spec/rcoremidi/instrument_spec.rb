require 'spec_helper'

RSpec.describe RCoreMidi::Instrument do

  subject do
    described_class.new(:instrument_name, 0) do
      play 1, :drum
    end
  end

  before do
    RCobreMidi::Clip.register(:drum) do
      note 'E5', [1, 0, 0, 0] * 4
    end
  end

  it_behaves_like 'registrable', [:instrument_name, :midi_channel]

  let(:bar)    { 1 }
  let(:clip)   { double(RCoreMidi::Clip) }
  let(:track)  { double(RCoreMidi::Track) }

  describe 'public API' do
    before do
      expect(subject).to receive(:track).and_return(track)
    end

    describe '#play'  do

      it 'adds a clip to the instrument track' do
        expect(RCoreMidi::Clip).to receive(:[]).with(:drum).and_return(clip)
        expect(track).to           receive(:play).with(bar, clip, false)

        subject.play(bar, :drum)
      end
    end

    describe '#generate_bar' do

      let(:duration_calculator) { double(RCoreMidi::DurationCalculator) }

      it "generates the current bar for the instrument's track" do
        expect(track).to   receive(:generate).with(bar, duration_calculator)

        subject.generate_bar(bar, duration_calculator)
      end
    end
  end
end
