require 'spec_helper'

RSpec.describe RCoreMidi::RythmSequence do

  let(:pitch)               { 'E4' }
  let(:probabilities)       { [1, 0, 0, 0] * 4 }
  let(:duration_calculator) { double(RCoreMidi::DurationCalculator) }
  let(:channel)             { 0 }
  let(:beat_resolution)     { 16 }

  before do
    allow(duration_calculator).to receive(:timestamps_for).and_return([0, 15000])
  end

  subject { described_class.new(pitch, beat_resolution, probabilities) }

  describe '#pitches' do
    it 'wraps a single pitch' do
      expect(subject.pitches).to eq(%w[E4])
    end
  end

  describe '#generate with several pitches' do
    let(:notes) { described_class.new(%w[G4 B4 D5], beat_resolution, [1, 0, 1, 0]).generate(false, channel) }

    it 'plays every pitch on each step that plays' do
      expect(notes.map { |note| note.on[1] }).to eq([67, 71, 74] * 2)
    end

    it 'starts the pitches of a step together' do
      expect(notes.map(&:on_timestamp).each_slice(3).map(&:uniq)).to all(have_attributes(size: 1))
    end
  end

  describe '#generate' do
    let(:random_generator)     { double(RCoreMidi::ProbabilityGenerator) }
    let(:not_random_generator) { double(RCoreMidi::ProbabilityGenerator) }
    let(:probability_generator) do
      { true => random_generator, false => not_random_generator }
    end

    before do
      expect(subject).
        to receive(:probability_generator).
             and_return(probability_generator).
             exactly(probabilities.size)
    end

    describe 'without random probability generator' do
      let(:enable_probability) { false }

      it 'generates new notes' do
        probabilities.each do |probability|
          expect(not_random_generator).to receive(:play?).with(probability)
        end

        subject.generate(enable_probability, channel)
      end

      describe 'with random probability' do
        let(:enable_probability) { true }

        it 'generates random probabilities' do

          probabilities.each do |probability|
            expect(random_generator).to receive(:play?).with(probability)
          end

          subject.generate(enable_probability, channel)
        end
      end

    end

  end
end
