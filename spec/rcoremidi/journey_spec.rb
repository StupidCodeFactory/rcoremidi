require 'spec_helper'

RSpec.describe RCoreMidi::Journey do
  let(:name) { :"journey_#{SecureRandom.hex(4)}" }
  let(:c_major) { Musicalism::Key['C major'] }

  def journey(**options, &walk)
    described_class.register(name, **{ rate: 1, seed: 1 }.merge(options), &walk)
  end

  def walk_of(journey, bars)
    (1..bars).map { |bar| journey.bar(bar) }
  end

  describe '.register' do
    it 'registers a named journey' do
      expect { journey(from: 'C major') }.to change { described_class[name] }.from(nil).to(instance_of(described_class))
    end

    it 'refuses an unknown mode' do
      expect { journey(from: 'C major', mode: :sideways) }
        .to raise_error(ArgumentError, 'sideways is not a journey mode, use up, down, up_down or random')
    end
  end

  describe 'modes' do
    it 'goes up one level per key until its range, then holds' do
      expect(walk_of(journey(from: 'C major', mode: :up, range: 3), 6).map(&:distance)).to eq([0, 1, 2, 3, 3, 3])
    end

    it 'goes down one level per key until home, then holds' do
      bars = walk_of(journey(from: 'F# major', home: 'C major', mode: :down), 8)

      expect(bars.map(&:distance)).to eq([6, 5, 4, 3, 2, 1, 0, 0])
    end

    it 'goes up to its range and back home, again and again' do
      expect(walk_of(journey(from: 'C major', mode: :up_down, range: 2), 9).map(&:distance))
        .to eq([0, 1, 2, 1, 0, 1, 2, 1, 0])
    end

    it 'wanders to a closely related key at random' do
      keys = walk_of(journey(from: 'C major', mode: :random), 20).map(&:key)

      expect(keys.each_cons(2).map { |previous, key| previous.distance_to(key) }).to all(eq(1))
    end

    it 'takes different walks with different seeds' do
      walks = (1..10).map do |seed|
        described_class.register(:"#{name}_#{seed}", from: 'C major', mode: :random, rate: 1, seed:)
        walk_of(described_class[:"#{name}_#{seed}"], 6).map { |bar| bar.key.to_s }
      end

      expect(walks.uniq.size).to be > 1
    end

    it 'repeats the same walk with the same seed' do
      first = walk_of(journey(from: 'C major', mode: :random, seed: 9), 12).map { |bar| bar.key.to_s }
      described_class.register(:"#{name}_again", from: 'C major', mode: :random, rate: 1, seed: 9)

      expect(walk_of(described_class[:"#{name}_again"], 12).map { |bar| bar.key.to_s }).to eq(first)
    end

    it 'walks with a block given the key, its closely related keys and home' do
      bars = walk_of(journey(from: 'C major') { |key, candidates, home| candidates.max_by { |candidate| candidate.distance_to(home) } }, 4)

      expect(bars.map(&:distance)).to eq([0, 1, 2, 3])
    end

    it 'gives the block the closely related keys of the current key' do
      offered = nil
      journey(from: 'C major') do |key, candidates, _home|
        offered ||= [key, candidates]
        candidates.first
      end.bar(2)

      expect(offered).to eq([c_major, c_major.closely_related])
    end
  end

  describe 'range and length' do
    it 'stops one level short of the farthest key with a negative range' do
      expect(walk_of(journey(from: 'C major', mode: :up, range: -1), 8).map(&:distance).max).to eq(6)
    end

    it 'goes to the farthest key by default' do
      expect(walk_of(journey(from: 'C major', mode: :up), 9).map(&:distance).max).to eq(7)
    end

    it 'reaches its range at the farthest key when the range is larger' do
      expect(walk_of(journey(from: 'C major', mode: :up, range: 20), 8).last).to be_farthest
    end

    it 'holds the last key after its number of steps' do
      keys = walk_of(journey(from: 'C major', mode: :up, steps: 3), 6).map { |bar| bar.key.to_s }

      expect(keys.drop(2).uniq).to eq([keys[2]])
    end
  end

  describe 'home' do
    it 'measures distance from another key' do
      expect(journey(from: 'C major', home: 'E major').bar(1).distance).to eq(c_major.distance_to('E major'))
    end
  end

  describe '#bar' do
    let(:voyage) { journey(from: 'C major', mode: :up_down, range: 1, rate: 4) }

    it 'keeps each key for rate bars' do
      expect(walk_of(voyage, 9).map { |bar| bar.key.to_s }.chunk_while { |a, b| a == b }.map(&:size)).to eq([4, 4, 1])
    end

    it 'counts the bars within each key' do
      expect(walk_of(voyage, 5).map(&:bar)).to eq([0, 1, 2, 3, 0])
    end

    it 'knows the first and last bar of each key' do
      expect([voyage.bar(5), voyage.bar(8)]).to match([be_first_bar, be_last_bar])
    end

    it 'gives the voice-led modulation into the key on each new key' do
      bar = voyage.bar(5)

      expect(bar.modulation.map(&:to_s)).to match([eq('C major'), anything, anything, eq(bar.key.to_s)])
    end

    it 'has no modulation while it holds a key' do
      expect(journey(from: 'C major', mode: :down).bar(2).modulation).to be_nil
    end

    it 'has no modulation on the first key' do
      expect(voyage.bar(1).modulation).to be_nil
    end

    it 'counts the bars until the music is home again' do
      expect(walk_of(voyage, 9).map(&:bars_until_home)).to eq([0, 0, 0, 0, 4, 3, 2, 1, 0])
    end

    it 'has no bars until home when the walk never comes back' do
      expect(journey(from: 'C major', mode: :up).bar(3).bars_until_home).to be_nil
    end

    it 'tells whether the music moves away, comes closer, arrives or reaches its range' do
      bars = walk_of(journey(from: 'C major', mode: :up_down, range: 1), 3)

      expect(bars).to match([be_arrived, be_away.and(be_farthest), be_toward.and(be_arrived)])
    end

    it 'refuses a bar before the first one' do
      expect { voyage.bar(0) }.to raise_error(ArgumentError, 'bars start at 1, got 0')
    end
  end

  describe 'steering a journey by registering it again' do
    it 'keeps the bars already prepared and plans the new mode from there' do
      journey(from: 'C major', mode: :up, range: 6)
      prepared = walk_of(described_class[name], 4).map { |bar| bar.key.to_s }
      journey(from: 'C major', mode: :down)

      expect(walk_of(described_class[name], 8)).to match(
        prepared.map { |key| have_attributes(key: have_attributes(to_s: key)) } +
          [have_attributes(distance: 2), have_attributes(distance: 1), have_attributes(distance: 0), have_attributes(distance: 0)]
      )
    end
  end
end
