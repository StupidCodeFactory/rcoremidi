require 'spec_helper'

RSpec.describe RCoreMidi::RythmSequence do

  let(:pitch)               { 'E4' }
  let(:probabilities)       { [1, 0, 0, 0] * 4 }
  let(:duration_calculator) { double(RCoreMidi::DurationCalculator) }
  let(:channel)             { 0 }

  before do
    allow(duration_calculator).to receive(:timestamps_for).and_return([0, 15000])
  end

  subject { described_class.new(pitch, probabilities) }

  describe '#generate' do

    let(:rythm_sequence) { subject.generate(probability, channel) }

    describe 'without random probability generator' do

      let(:probability) { true }

      it 'generates new notes' do
        expect(rythm_sequence).to eq([
          RCoreMidi::Note.new(pitch, 0, 15000, channel),
          nil, nil, nil,
          RCoreMidi::Note.new(pitch, 0, 15000, channel),
          nil, nil, nil,
          RCoreMidi::Note.new(pitch, 0, 15000, channel),
          nil, nil, nil,
          RCoreMidi::Note.new(pitch, 0, 15000, channel),
          nil, nil, nil
        ])
      end

      describe 'with random probability' do

        let(:probability)           { false }
        let(:probability_generator) { double(RCoreMidi::ProbabilityGenerator) }
        let(:probabilities)         { [0.5, 0, 0.2, 0] }

        before do
          allow(RCoreMidi::ProbabilityGenerator).to receive(:new).and_return(probability_generator)
          expect(probability_generator).to receive(:play?).with(0.5).and_return(false)
          expect(probability_generator).to receive(:play?).with(0.2).and_return(true)
          expect(probability_generator).to receive(:play?).with(0).twice.and_return(false)
        end


        it 'generates random probabilities' do
          expect(rythm_sequence).to eq(
            [
              nil, nil,
              RCoreMidi::Note.new(pitch, 0, 15000, channel),
              nil
            ])
        end

      end
    end
  end
end
