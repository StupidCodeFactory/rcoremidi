require 'spec_helper'
require 'byebug'
module RCoreMidi
  describe NoteSequenceGenerator do
    describe '.generate' do
      describe 'with a string representation of a note, an array of float as probabilities' do
        let(:probabilities) do
          Generator.new [ 1.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0 ]
        end
        let(:channel)      { 1 }
        let(:note)         { 'C3' }
        let(:notes)        { subject.generate(note, probabilities, channel)}
        let(:mpt)          { 20833.333333333332 }
        subject            { NoteSequenceGenerator.new(mpt) }

        it 'returns an array with notes only having a probabilty > 0' do
          expect(notes.size).to eq(16)
        end

        it 'generates an array of notes with the corresponding timestamps offsets' do
          ap notes
          expect(notes[0].on_timestamp).to eq(0)
          expect(notes[1].on_timestamp).to eq(2  * 6 * mpt)
          expect(notes[2].on_timestamp).to eq(7  * 6 * mpt)
          expect(notes[3].on_timestamp).to eq(9  * 6 * mpt)
          expect(notes[4].on_timestamp).to eq(10 * 6 * mpt)
        end
      end
    end
  end
end
