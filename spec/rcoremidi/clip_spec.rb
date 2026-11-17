require 'spec_helper'

RSpec.describe RCoreMidi::Clip do

  let(:definition) do
    Proc.new do
      note 'E5', [1,0,0,0] * 4
    end
  end

  subject { described_class.new(:clip_name, &definition) }

  it_behaves_like 'registrable', [:clip_name]

  def clip_with(&definition)
    described_class.new(:clip_name).tap { |clip| clip.load(&definition) }
  end

  describe '#note' do
    let(:rythm_sequence) { instance_double(RCoreMidi::RythmSequence) }
    let(:pitch)          { 'E5' }
    let(:notes)          { [1,0,0,0] * 4 }
    let(:beat_resolution) { 16 }

    it 'parses RythmSequence' do
      expect(RCoreMidi::RythmSequence).to receive(:new).with(pitch, beat_resolution, notes).and_return(rythm_sequence)
      subject.note(pitch, beat_resolution, notes)

      expect(subject.rythm_sequences).to eq([rythm_sequence])
    end

    it 'plays a scale degree of the clip key' do
      clip = clip_with do
        key 'A minor'
        note 5, 16, [1, 0, 0, 0] * 4
      end

      expect(clip.rythm_sequences.map(&:pitches)).to eq([%w[E5]])
    end

    it 'asks for a key before a scale degree' do
      expect { clip_with { note 5, 16, [1] } }
        .to raise_error(ArgumentError, "set the clip key first, e.g. key 'C major'")
    end
  end

  describe '#key' do
    it 'reads the key from its name' do
      expect(clip_with { key 'F# minor' }.key).to eq(Musicalism::Key.minor('F#'))
    end

    it 'is forgotten when the clip file is reloaded' do
      clip = clip_with { key 'C major' }
      clip.load {}

      expect(clip.key).to be_nil
    end
  end

  describe '#chord' do
    it 'plays the chord on a roman numeral of the clip key as one sequence' do
      clip = clip_with do
        key 'C major'
        chord :V, 16, [1, 0, 0, 0] * 4
      end

      expect(clip.rythm_sequences.map(&:pitches)).to eq([%w[G4 B4 D5]])
    end

    it 'inverts the chord' do
      clip = clip_with do
        key 'C major'
        chord :vi, 16, [1], inversion: 1
      end

      expect(clip.rythm_sequences.map(&:pitches)).to eq([%w[C5 E5 A5]])
    end

    it 'plays a musicalism chord as given' do
      clip = clip_with do
        chord Musicalism::Key.minor('A').chord(:V), 16, [1]
      end

      expect(clip.rythm_sequences.map(&:pitches)).to eq([%w[E5 G#5 B5]])
    end
  end

  describe '#modulate' do
    let(:clip) do
      clip_with do
        key 'C major'
        modulate to: 'G major', via: :vi
      end
    end

    it 'plays one voice-led chord of the modulation per bar' do
      expect((0..3).map { |bar_offset| clip.rythm_sequences_for(bar_offset).map(&:pitches) })
        .to eq([[%w[C4 E4 G4]], [%w[C4 E4 A4]], [%w[D4 F#4 A4]], [%w[D4 G4 B4]]])
    end

    it 'plays every chord in root position in its own key without voice leading' do
      clip = clip_with do
        key 'C major'
        modulate to: 'G major', via: :vi, voice_leading: false
      end

      expect(clip.rythm_sequences_for(2).map(&:pitches)).to eq([%w[D5 F#5 A5]])
    end

    it 'starts the modulation again after its last bar' do
      expect(clip.rythm_sequences_for(4).map(&:pitches)).to eq([%w[C4 E4 G4]])
    end

    it 'hits each chord on the first step of the bar by default' do
      expect(clip.rythm_sequences_for(0).map(&:probabilities)).to eq([[1] + [0] * 15])
    end

    it 'takes a rhythm for its chords' do
      clip = clip_with do
        key 'C major'
        modulate to: 'G major', rhythm: [1, 0, 1, 0] * 4
      end

      expect(clip.rythm_sequences_for(1).map(&:probabilities)).to eq([[1, 0, 1, 0] * 4])
    end

    it 'keeps the notes and chords that play on every bar' do
      clip = clip_with do
        key 'C major'
        note 1, 16, [1]
        modulate to: 'G major', via: :vi
      end

      expect(clip.rythm_sequences_for(1).map(&:pitches)).to eq([%w[C4], %w[C4 E4 A4]])
    end

    it 'asks for a key to modulate from' do
      expect { clip_with { modulate to: 'G major' } }
        .to raise_error(ArgumentError, "set the clip key first, e.g. key 'C major'")
    end
  end
end
