require 'spec_helper'

RSpec.describe RCoreMidi::Track do

  before do
    RCoreMidi::Clip.register(clip_name) do
      note 'E5', [1,0,1,0] * 4
      note 'D5', [1,1,1] * 4
    end
  end

  let(:ppqn)      { 24 }
  let(:clip_name) { :drum }
  let(:clip)      { RCoreMidi::Clip[clip_name] }

  describe '#play' do
    context 'when given a single bar' do
      let(:bar) { 1 }

      context 'when there are not notes yet' do
        it "add clip notes to given bar" do
          subject.play bar, clip

          expect(subject.bars[bar]).to eq(clip.beats)
          expect(subject.bars[bar][0]).to  include(RCoreMidi::Note.new('D5'), RCoreMidi::Note.new('E5'))
          expect(subject.bars[bar][8]).to  include(RCoreMidi::Note.new('D5'))
          expect(subject.bars[bar][12]).to include(RCoreMidi::Note.new('E5'))
          expect(subject.bars[bar][16]).to include(RCoreMidi::Note.new('D5'))

          expect(subject.bars[bar][0  + ppqn]).to include(RCoreMidi::Note.new('D5'), RCoreMidi::Note.new('E5'))
          expect(subject.bars[bar][8  + ppqn]).to include(RCoreMidi::Note.new('D5'))
          expect(subject.bars[bar][12 + ppqn]).to include(RCoreMidi::Note.new('E5'))
          expect(subject.bars[bar][16 + ppqn]).to include(RCoreMidi::Note.new('D5'))

          expect(subject.bars[bar][0  + ppqn * 2]).to include(RCoreMidi::Note.new('D5'), RCoreMidi::Note.new('E5'))
          expect(subject.bars[bar][8  + ppqn * 2]).to include(RCoreMidi::Note.new('D5'))
          expect(subject.bars[bar][12 + ppqn * 2]).to include(RCoreMidi::Note.new('E5'))
          expect(subject.bars[bar][16 + ppqn * 2]).to include(RCoreMidi::Note.new('D5'))

          expect(subject.bars[bar][0  + ppqn * 3]).to include(RCoreMidi::Note.new('D5'), RCoreMidi::Note.new('E5'))
          expect(subject.bars[bar][8  + ppqn * 3]).to include(RCoreMidi::Note.new('D5'))
          expect(subject.bars[bar][12 + ppqn * 3]).to include(RCoreMidi::Note.new('E5'))
          expect(subject.bars[bar][16 + ppqn * 3]).to include(RCoreMidi::Note.new('D5'))
        end
      end
    end
  end
end
