require 'spec_helper'

RSpec.describe RCoreMidi::Track do

  let(:clip)               do
    RCoreMidi::Clip.new(:drum) do
      note 'E5', [1, 0, 0, 0] * 4
    end
  end

  let(:bar)                { 1 }
  let(:enable_probability) { false }
  let(:clips)              { {} }

  describe '#play' do

    it "stores what clip to play for a given bar and configuration" do
      expect(subject).to receive(:clips).and_return(clips)

      subject.play bar, clip, enable_probability

      expect(clips).to eq(bar => [clip, enable_probability])
    end

  end

  describe '#generate' do

    let(:duration_calculator) { RCoreMidi::DurationCalculator.new(120) }

    before do
      subject.play(1, clip, enable_probability)
    end

    context 'with no probability generator disabled' do
      it "generates notes" do
        expect(subject.generate(1, duration_calculator)).to eq(
          [
            RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(0)),
            RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(4)),
            RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(8)),
            RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(12)),
          ]
        )
      end
    end
  end

end
