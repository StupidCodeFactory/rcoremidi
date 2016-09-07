require 'spec_helper'

module RCoreMidi

  describe Note do
    let(:channel) { 1 }
    let(:note)    { Note.new('D4', 34, 0, 123, channel) }

    describe '#on' do
      it 'returns the channel, midi note, ' do
        expect(note.on).to eq([channel | Note::NOTE_ON, 38, 34])
      end
    end

    describe '#off' do
      it 'returns the midi note code and velocity' do
        expect(note.off).to eq([channel | Note::NOTE_OFF, 38, 34])
      end
    end

  end

  describe Instrument do

    describe '#add' do
      describe 'when adding a note sequence to the track' do

        let(:instrument) { Instrument.new(:test) }

        describe 'with an invalid note name' do
          it 'raises an error' do
            pending "Not there yet"
            expect { instrument.add('D4', []) }.to raise_error(InvalidNotName, 'D is not a valid note name')
          end
        end

        describe 'whith a valid note name' do
          it 'add the note to the track' do
            pending "Not there yet"
            expect { instrument.add('C##3', []) }.to change { instrument.send(:track).size }.by(1)
          end
        end

      end
    end

  end

end
