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
    it "return notes" do
      expect(subject.generate_beats(1)).to eq('asdasd')
    end
  end
end
