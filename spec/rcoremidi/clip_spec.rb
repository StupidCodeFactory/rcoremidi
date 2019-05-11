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
    let(:e5)        { 'E5' }
    let(:d5)        { 'D5' }
    let(:e5_rhythm) { [1,0,1,0] * 4 }
    let(:d5_rhythm) { [1,1,1] * 4 }
    let(:ppqn)      { 24 }

    it 'parses RythmSequence' do
      subject.note(e5, e5_rhythm)
      subject.note(d5, d5_rhythm)

      expect(subject.beats[0]).to include(RCoreMidi::Note.new('D5'), RCoreMidi::Note.new('E5'))
      expect(subject.beats[8]).to include(RCoreMidi::Note.new('D5'))
      expect(subject.beats[12]).to include(RCoreMidi::Note.new('E5'))
      expect(subject.beats[16]).to include(RCoreMidi::Note.new('D5'))

      expect(subject.beats[0  + ppqn]).to include(RCoreMidi::Note.new('D5'), RCoreMidi::Note.new('E5'))
      expect(subject.beats[8  + ppqn]).to include(RCoreMidi::Note.new('D5'))
      expect(subject.beats[12 + ppqn]).to include(RCoreMidi::Note.new('E5'))
      expect(subject.beats[16 + ppqn]).to include(RCoreMidi::Note.new('D5'))

      expect(subject.beats[0  + ppqn * 2]).to include(RCoreMidi::Note.new('D5'), RCoreMidi::Note.new('E5'))
      expect(subject.beats[8  + ppqn * 2]).to include(RCoreMidi::Note.new('D5'))
      expect(subject.beats[12 + ppqn * 2]).to include(RCoreMidi::Note.new('E5'))
      expect(subject.beats[16 + ppqn * 2]).to include(RCoreMidi::Note.new('D5'))

      expect(subject.beats[0  + ppqn * 3]).to include(RCoreMidi::Note.new('D5'), RCoreMidi::Note.new('E5'))
      expect(subject.beats[8  + ppqn * 3]).to include(RCoreMidi::Note.new('D5'))
      expect(subject.beats[12 + ppqn * 3]).to include(RCoreMidi::Note.new('E5'))
      expect(subject.beats[16 + ppqn * 3]).to include(RCoreMidi::Note.new('D5'))
    end
  end
end
