require 'spec_helper'

module RCoreMidi

  describe Note do
    let(:note) { Note.new('D4', 34) }

    describe '#to_midi' do
      it 'returns the midi note code and velocity' do
        expect(note.to_midi).to eq([38, 34])
      end
    end
  end

  describe Instrument do

    describe '#add' do
      describe 'when adding a note sequence to the track' do

        let(:instrument) { Instrument.new(:test) }

        describe 'with an invalid note name' do
          it 'raises an error' do
            expect { instrument.add('D', []) }.to raise_error(InvalidNotName, 'D is not a valid note name')
          end
        end

        describe 'whith a valid note name' do
          it 'add the note to the track' do
            expect { instrument.add('C##3', []) }.to change { instrument.send(:track).size }.by(1)
          end
        end

      end
    end

  end

end
