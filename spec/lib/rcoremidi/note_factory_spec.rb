require 'spec_helper'
require 'byebug'
module RCoreMidi
  describe NoteFactory do
    describe '.generate' do
      describe 'with a string representation of a note, an array of float as probabilities' do

        let(:note)         { 'C3' }
        let(:probabilities) do
          [ 1.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0 ]
        end
        let(:notes)        { subject.generate(note, probabilities)}
        subject            { NoteFactory.new(mpt) }
        let(:mpt)          { 20833.333333333332 }

        it 'returns an array with notes only having a probabilty > 0' do
          expect(notes.size).to eq(5)
        end

        it 'generates an array of notes with the corresponding timestamps offsets' do
          expect(notes[0].at_offset).to eq(0)
          expect(notes[1].at_offset).to eq(2  * 6 * mpt)
          expect(notes[2].at_offset).to eq(7  * 6 * mpt)
          expect(notes[3].at_offset).to eq(9  * 6 * mpt)
          expect(notes[4].at_offset).to eq(10 * 6 * mpt)
        end
      end
    end
  end
end
