require 'spec_helper'

RSpec.describe RCoreMidi::Live do

  let(:bpm)      { 120 }
  let(:clip_dir) { File.join('spec', 'fixtures', 'clips') }
  let(:clip)     { double(RCoreMidi::Clip) }

  subject { described_class.new(bpm, clip_dir) }

  before do
    expect(RCoreMidi::Clip).to receive(:new).and_return(clip)
  end

  describe '#load_clips' do
    it 'loads clips from file' do
      expect {
        subject.load_clips
      }.to change { subject.clip :drum }.from(nil).to(clip)
    end
  end

end
