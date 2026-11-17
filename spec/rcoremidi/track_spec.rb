require 'spec_helper'

RSpec.describe RCoreMidi::Track do

  subject { described_class.new(0) }

  let(:duration_calculator) { RCoreMidi::DurationCalculator.new(120) }

  def clip_with(&definition)
    RCoreMidi::Clip.new(:clip_name).tap { |clip| clip.load(&definition) }
  end

  describe '#generate' do
    context 'with no probability generator disabled' do
      it "generates notes" do
        subject.play(1, clip_with { note 'E5', 16, [1, 0, 0, 0] * 4 }, false)

        expect(subject.generate(1)).to eq(
          [
            RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(0)),
            RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(4)),
            RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(8)),
            RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(12)),
          ]
        )
      end
    end

    it 'plays the bar of a multi-bar clip that matches the bar offset' do
      clip = clip_with do
        key 'C major'
        modulate to: 'G major', via: :vi
      end
      subject.play(5, clip, false, 1)

      expect(subject.generate(5).map { |note| note.on[1] }).to eq([60, 64, 69])
    end

    it 'plays nothing on a bar without a clip' do
      expect(subject.generate(3)).to be_empty
    end
  end
end
