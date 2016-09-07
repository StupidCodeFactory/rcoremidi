require 'spec_helper'

RSpec.describe RCoreMidi::Clip do

  let(:definition) do
    Proc.new do
      note 'E5', [1,0,0,0] * 4
    end
  end

  subject { described_class.new(:clip_name, &definition) }

  it_behaves_like 'registrable', [:clip_name]

  describe '#call' do

    let(:rythm_sequence) { double(RCoreMidi::RythmSequence) }
    let(:notes)          { [] }

    it 'creates a rythm sequence for the given pitch' do
      expect(RCoreMidi::RythmSequence).to receive(:new).with(
        'E5', [1,0,0,0] * 4,
        instance_of(RCoreMidi::ProbabilityGenerator),
        nil
      ).and_return(rythm_sequence)
      expect(subject).to receive(:notes).and_return(notes)
      subject.call
      expect(notes).to eq([rythm_sequence])
    end
  end
end
