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

    it 'gives the song bar to clips that follow a journey' do
      RCoreMidi::Journey.register(:track_voyage, from: 'C major', mode: :up, rate: 1, seed: 5)
      clip = clip_with { follow(:track_voyage) { |key, _step| note 1, 16, [1] } }
      subject.play(3, clip, false, 0)

      expect(subject.generate(3).map { |note| note.on[1] }).to eq([RCoreMidi::Journey[:track_voyage].bar(3).key.note(1).to_midi])
    end

    it 'plays the same journey key in every clip that follows it' do
      RCoreMidi::Journey.register(:shared_voyage, from: 'C major', mode: :random, rate: 2, seed: 8)
      bass = clip_with { follow(:shared_voyage) { |key, _step| note 1, 16, [1] } }
      pads = clip_with { follow(:shared_voyage) { |key, _step| note 1, 16, [1] } }
      other = described_class.new(1)
      (1..40).each do |bar|
        subject.play(bar, bass, false, 0)
        other.play(bar, pads, false, 0)
      end

      expect((1..40).map { |bar| subject.generate(bar).map { |note| note.on[1] } })
        .to eq((1..40).map { |bar| other.generate(bar).map { |note| note.on[1] } })
    end

    it 'plays nothing on a bar without a clip' do
      expect(subject.generate(3)).to be_empty
    end
  end
end
