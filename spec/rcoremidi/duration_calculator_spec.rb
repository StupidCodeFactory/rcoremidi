require 'spec_helper'

module RCoreMidi
  RSpec.describe DurationCalculator do
    let(:bpm) { 60 }
    let(:ppqn) { 960 }
    let(:mpt) { 60000000 / (bpm *  ppqn).to_f }

    subject { DurationCalculator.new(bpm) }

    describe '#timestamps_for' do

      it 'returns a note with the correct timstamps' do
        ts = subject.timestamps_for 0
        expect(ts.first).to eq(0)
        expect(ts.last).to eq(ts.first + (240 * mpt).round)

        ts = subject.timestamps_for 1
        expect(ts.first).to eq((1 * 480 * mpt).round)
        expect(ts.last).to eq(ts.first + (240 * mpt).round)
      end
    end

  end
end
