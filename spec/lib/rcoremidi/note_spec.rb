require 'spec_helper'

module RCoreMidi
  RSpec.describe Note do
    let(:note) { Note.new('C3', 90, 0, 1, 15) }

    describe '#on' do
      it 'returns the status, midi note number and velocity' do
        expect(note.on).to eq [159, 24, 90]
      end
    end

    describe '#off' do
      it 'returns the status, midi note number and velocity' do
        expect(note.off).to eq [143, 24, 90]
      end
    end

  end
end
