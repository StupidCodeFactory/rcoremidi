require 'spec_helper'

RSpec.describe RCoreMidi::Instrument do

  subject do
    described_class.new(:instrument_name, 0) do
      play 1, :drum
    end
  end

  before do
    RCoreMidi::Clip.register(:drum) do
      note 'E5', 16, [1, 0, 0, 0] * 4
    end
  end

  it_behaves_like 'registrable', [:instrument_name, :midi_channel]

  let(:bar)    { 1 }
  let(:clip)   { instance_double(RCoreMidi::Clip, add_observer: nil) }
  let(:track)  { instance_double(RCoreMidi::Track) }

  describe 'playing a bar range' do
    subject do
      described_class.new(:instrument_name, 0) do
        play 1..4, :drum
      end.tap(&:load)
    end

    it 'plays every bar of the range, the last one included' do
      expect((1..4).map { |bar| subject.generate_bar(bar) }).to all(be_any)
    end

    it 'picks up a clip file reloaded after it started playing it' do
      subject
      RCoreMidi::Clip.register(:drum) { note 'G5', 16, [1] }

      expect(subject.generate_bar(1).map { |note| note.on[1] }).to eq([79])
    end
  end

  describe 'public API' do
    before do
      allow(subject).to receive(:track).and_return(track)
      allow(RCoreMidi::Clip).to receive(:[]).with(:drum).and_return(clip)
    end

    describe '#play'  do

      it 'adds a clip to the instrument track' do
        expect(track).to receive(:play).with(bar, clip, false)

        subject.play(bar, :drum)
      end

      it 'tells the track how far into a bar range each bar is' do
        expect(track).to receive(:play).with(5, clip, false, 0).ordered
        expect(track).to receive(:play).with(6, clip, false, 1).ordered
        expect(track).to receive(:play).with(7, clip, false, 2).ordered

        subject.play(5..7, :drum)
      end
    end

    describe '#generate_bar' do
      it "generates the current bar for the instrument's track" do
        expect(track).to receive(:generate).with(bar)

        subject.generate_bar(bar)
      end
    end
  end
end
