require 'spec_helper'
require 'rcoremidi/cli'

RSpec.describe RCoreMidi::Live do
  let(:fixtures_root) { RCoreMidi::AppPathname.new(File.join('spec', 'fixtures')) }
  let(:duration_calculator) { RCoreMidi::DurationCalculator.new(120) }

  before do
    allow(RCoreMidi::Application).to receive(:root).and_return(fixtures_root)
    RCoreMidi::Application.load_clips!
    RCoreMidi::Application.load_instruments!
  end

  describe '#generate_beats' do
    it 'returns the notes every instrument plays on the bar' do
      expect(subject.generate_beats(bar: 1)).to eq([
        RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(0)),
        RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(4)),
        RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(8)),
        RCoreMidi::Note.new('E5', *duration_calculator.timestamps_for(12))
      ])
    end
  end
end
