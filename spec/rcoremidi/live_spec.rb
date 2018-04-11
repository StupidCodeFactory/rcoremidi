require 'spec_helper'

RSpec.describe RCoreMidi::Live do

  let(:bpm)             { 120 }
  let(:clip_dir)        { File.join('spec', 'fixtures', 'clips') }
  let(:instruments_dir) { File.join('spec', 'fixtures', 'instruments') }

  # subject { described_class.new(bpm, clip_dir, instruments_dir) }

  before do
      Dir["#{clip_dir}/**/*.rb"].each { |f| load f }
      Dir["#{instruments_dir}/**/*.rb"].each { |f| load f }
    end
  describe '#load_clip' do
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

  describe '#load' do

    it "loads the given bar" do
      subject.load
      ap subject.beats
      # expect(subject.bars).to eq({})
      # RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(0)),
      # RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(4)),
      # RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(8)),
      # RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(12)),
    end
  end

  describe '#sequence!' do
    let(:sequencer) { RCoreMidi::Sequencer }
    before do
      expect(RCoreMidi::Sequencer).to receive(:new).and_return(sequencer)
    end

    it 'prepares the first bar sequence' do
      subject.sequence!
    end
  end
end
