require 'spec_helper'

RSpec.describe RCoreMidi::Clip do

  let(:definition) do
    Proc.new do
      note 'E5', [1,0,0,0] * 4
    end
  end

  subject { described_class.new(:clip_name, &definition) }

  it_behaves_like 'registrable', [:clip_name]

  describe '#note' do
    let(:rythm_sequence) { instance_double(RCoreMidi::RythmSequence) }
    let(:pitch)          { 'E5' }
    let(:notes)          { [1,0,0,0] * 4 }
    let(:raw_rythm_clip) do
      { 16 => notes }
    end

    it 'parses RythmSequence' do
      expect(RCoreMidi::RythmSequence).to receive(:new).with(pitch, raw_rythm_clip).and_return(rythm_sequence)
      subject.note(pitch, raw_rythm_clip)

      expect(subject.rythm_sequences).to eq([rythm_sequence])
    end
  end
end
