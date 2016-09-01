require 'spec_helper'
require 'byebug'
module RCoreMidi
  describe NoteFactory do
    describe '.generate' do
      describe 'with a string representation of a note, an array of float as probabilities' do
        let(:probabilities) do
          [
            1.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
            0.0, 1.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 0.0
          ]
        end
        let(:pitch)         { 'C3' }
        let(:notes)        { subject.generate(pitch)}
        subject            { NoteFactory.new(probabilities, DurationCalculator.new(60)) }

        it 'returns an array with notes only having a probabilty > 0' do
          expect(notes.size).to eq(16)
        end

        it 'generates an array of notes with the corresponding timestamps offsets' do
          # first quarter note
          expect(notes[0].on_timestamp).to eq(0)
          expect(notes[0].off_timestamp).to eq(250_000)

          # third eigthth note
          expect(notes[2].on_timestamp).to eq(1_000_000)
          expect(notes[2].off_timestamp).to eq(1_250_000)

          # eigthth eigthth note
          expect(notes[7].on_timestamp).to eq(3_500_000)
          expect(notes[7].off_timestamp).to eq(3_750_000)


          # thenth eigthth note
          expect(notes[9].on_timestamp).to eq(4_500_000)
          expect(notes[9].off_timestamp).to eq(4_750_000)

          # eleventh eigthth note
          expect(notes[10].on_timestamp).to eq(5_000_000)
          expect(notes[10].off_timestamp).to eq(5_250_000)
          ap notes
        end
      end
    end
  end
end
