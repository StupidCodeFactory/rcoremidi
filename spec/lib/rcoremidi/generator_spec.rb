require 'spec_helper'
module RCoreMidi
  RSpec.describe Generator do

    let(:probablities) { [ 1.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0 ] }
    let(:mpt)          { 20833.333333333332 }
    let(:note)         { 'C3' }
    let(:channel)      { 1 }
    let(:duration_calculator) { 120 }

    subject { Generator.new(note, probablities) }
    let(:notes) { subject.generate }

    it 'generates an array of notes with the corresponding timestamps offsets' do
      expect(notes[0].on_timestamp).to eq(0)
      expect(notes[1].on_timestamp).to eq(2  * 6 * mpt)
      expect(notes[2].on_timestamp).to eq(7  * 6 * mpt)
      expect(notes[3].on_timestamp).to eq(9  * 6 * mpt)
      expect(notes[4].on_timestamp).to eq(10 * 6 * mpt)
    end

  end
end
