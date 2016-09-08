require 'spec_helper'

RSpec.describe RCoreMidi::Live do

  let(:bpm)             { 120 }
  let(:clip_dir)        { File.join('spec', 'fixtures', 'clips') }
  let(:instruments_dir) { File.join('spec', 'fixtures', 'instruments') }

  subject { described_class.new(bpm, clip_dir, instruments_dir) }

  describe '#load_clips' do
    it 'loads clips from file' do
      subject
      expect(RCoreMidi::Clip[:drum]).to be_instance_of(RCoreMidi::Clip)
    end
  end

  describe '#load_instruments' do
    it 'loads clips from file' do
      subject
      expect(RCoreMidi::Instrument[:drum]).to be_instance_of(RCoreMidi::Instrument)
    end
  end

  describe '#generate_beats' do
    let(:duration_calculator) { RCoreMidi::DurationCalculator.new(120) }
    it "return notes" do
      expect(subject.generate_beats(1)).to eq([
        RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(0)),
        RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(4)),
        RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(8)),
        RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(12)),
      ])
    end
  end
end
