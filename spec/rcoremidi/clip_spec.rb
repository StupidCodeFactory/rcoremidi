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

  describe '#follow' do
    let(:journey_name) { :"voyage_#{SecureRandom.hex(4)}" }

    before do
      RCoreMidi::Journey.register(journey_name, from: 'C major', mode: :up, range: 2, rate: 4, seed: 3)
    end

    def journey_bar(bar)
      RCoreMidi::Journey[journey_name].bar(bar)
    end

    it 'plays in the key of the journey on each bar' do
      name = journey_name
      clip = clip_with do
        follow(name) { |key, _step| chord key.chord(:I), 16, [1] }
      end

      expect([1, 5, 9].map { |bar| clip.rythm_sequences_for(0, bar).map(&:pitches) })
        .to eq([1, 5, 9].map { |bar| [journey_bar(bar).key.chord(:I).notes.map { |note| "#{note.pitch}#{note.octave}" }] })
    end

    it 'resolves scale degrees and numerals in the journey key' do
      name = journey_name
      clip = clip_with do
        follow(name) do |_key, _step|
          note 1, 16, [1]
          chord :V, 16, [1]
        end
      end
      key = journey_bar(5).key

      expect(clip.rythm_sequences_for(0, 5).map(&:pitches))
        .to eq([["#{key.note(1).pitch}#{key.note(1).octave}"], key.chord(:V).notes.map { |note| "#{note.pitch}#{note.octave}" }])
    end

    it 'gives the bar of the journey to the block' do
      name = journey_name
      seen = []
      clip = clip_with { follow(name) { |_key, step| seen << [step.bar, step.distance] } }
      (1..5).each { |bar| clip.rythm_sequences_for(0, bar) }

      expect(seen).to eq([[0, 0], [1, 0], [2, 0], [3, 0], [0, 1]])
    end

    it 'adds the sequences that play on every bar' do
      name = journey_name
      clip = clip_with do
        note 'C#2', 16, [1]
        follow(name) { |_key, step| note 'D2', 16, [1] if step.first_bar? }
      end

      expect([1, 2].map { |bar| clip.rythm_sequences_for(0, bar).map(&:pitches) }).to eq([[%w[C#2], %w[D2]], [%w[C#2]]])
    end

    it 'keeps its own key and sequences outside the journey bars' do
      name = journey_name
      clip = clip_with do
        key 'A minor'
        note 1, 16, [1]
        follow(name) { |_key, _step| note 1, 16, [1] }
      end
      clip.rythm_sequences_for(0, 5)

      expect([clip.key, clip.rythm_sequences.map(&:pitches)]).to eq([Musicalism::Key['A minor'], [%w[A4]]])
    end

    it 'plays only its own sequences when no song bar is given' do
      name = journey_name
      clip = clip_with do
        note 'C#2', 16, [1]
        follow(name) { |_key, _step| note 'D2', 16, [1] }
      end

      expect(clip.rythm_sequences_for(0).map(&:pitches)).to eq([%w[C#2]])
    end

    it 'asks for a journey that exists' do
      clip = clip_with { follow(:nowhere) { |_key, _step| } }

      expect { clip.rythm_sequences_for(0, 1) }.to raise_error(ArgumentError, 'Journey nowhere not found.')
    end

    it 'stops following when the clip file is reloaded without it' do
      name = journey_name
      clip = clip_with { follow(name) { |_key, _step| note 'D2', 16, [1] } }
      clip.load {}

      expect(clip.rythm_sequences_for(0, 1)).to be_empty
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
