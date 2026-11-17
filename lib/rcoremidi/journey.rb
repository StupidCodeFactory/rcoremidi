require 'forwardable'
require 'musicalism'
require 'rcoremidi/registrable'

module RCoreMidi
  class Journey
    include Registrable

    MODES = %i[up down up_down random].freeze
    FIRST_BAR = 1

    Step = Data.define(:key, :previous_key, :distance, :direction, :number, :first_bar, :bars, :peak, :modulation) do
      def away? = direction == :away
      def toward? = direction == :toward
      def arrived? = distance.zero?
      def farthest? = distance >= peak
      def last_bar = first_bar + bars - 1
      def covers?(bar) = bar.between?(first_bar, last_bar)
    end

    Bar = Data.define(:step, :song_bar, :bars_until_home) do
      extend Forwardable

      def_delegators :step, :key, :previous_key, :distance, :direction, :modulation, :bars,
                     :away?, :toward?, :arrived?, :farthest?

      def bar = song_bar - step.first_bar
      def first_bar? = bar.zero?
      def last_bar? = bar == bars - 1
    end

    class << self
      def register(name, **options, &walk)
        @registry[name] = @registry.key?(name) ? @registry[name].steer(**options, &walk) : new(name, **options, &walk)
      end
    end

    attr_reader :name

    def initialize(name, **options, &walk)
      @name = name
      @prepared_until = 0
      configure(**options, &walk)
      @planned = [first_step]
    end

    def steer(**options, &walk)
      configure(**options, &walk)
      @planned = @planned.select { |step| step.first_bar <= @prepared_until }
      @planned = [first_step] if @planned.empty?
      self
    end

    def bar(song_bar)
      raise ArgumentError, "bars start at #{FIRST_BAR}, got #{song_bar}" if song_bar < FIRST_BAR

      @prepared_until = [@prepared_until, song_bar].max
      step = step_at(song_bar)
      Bar.new(step:, song_bar:, bars_until_home: bars_until_home(step, song_bar))
    end

    private

    attr_reader :from, :home, :mode, :range, :rate, :steps, :walk, :random

    def configure(from:, mode: :up_down, range: :farthest, rate: 4, steps: nil, home: nil, seed: nil, &walk)
      raise ArgumentError, "#{mode} is not a journey mode, use up, down, up_down or random" unless MODES.include?(mode)

      @from = Musicalism::Key.coerce(from)
      @home = home ? Musicalism::Key.coerce(home) : @from
      @mode = mode
      @range = range
      @rate = rate
      @steps = steps
      @walk = walk
      @random = seed ? Random.new(seed) : Random.new
    end

    def first_step
      Step.new(key: from, previous_key: nil, distance: from.distance_to(home), direction: :level,
               number: 0, first_bar: FIRST_BAR, bars: rate, peak:, modulation: nil)
    end

    def step_at(song_bar)
      @planned << next_step(@planned.last) until @planned.last.covers?(song_bar) || @planned.last.first_bar > song_bar
      @planned.find { |step| step.covers?(song_bar) }
    end

    def bars_until_home(step, song_bar)
      return 0 if step.arrived?

      plan_steps(step.number + lookahead_steps)
      homecoming = @planned.drop(step.number + 1).find(&:arrived?)
      homecoming && homecoming.first_bar - song_bar
    end

    def lookahead_steps
      2 * home.farthest_distance + 1
    end

    def plan_steps(count)
      @planned << next_step(@planned.last) while @planned.size <= count
    end

    def next_step(step)
      key = next_key(step)
      distance = key.distance_to(home)
      Step.new(key:, previous_key: step.key, distance:, direction: direction_between(step.distance, distance),
               number: step.number + 1, first_bar: step.last_bar + 1, bars: rate, peak:,
               modulation: modulation_between(step.key, key))
    end

    def next_key(step)
      return step.key if steps && step.number + 1 >= steps

      candidates = step.key.closely_related
      chosen = walk ? walk.call(step.key, candidates, home) : send(:"walk_#{mode}", step, candidates)
      chosen ? Musicalism::Key.coerce(chosen) : step.key
    end

    def walk_up(step, candidates)
      one_level_from(step, candidates, +1) unless step.distance >= peak
    end

    def walk_down(step, candidates)
      one_level_from(step, candidates, -1) unless step.arrived?
    end

    def walk_up_down(step, candidates)
      heading_home?(step) ? walk_down(step, candidates) : walk_up(step, candidates)
    end

    def walk_random(_step, candidates)
      candidates.sample(random:)
    end

    def heading_home?(step)
      !step.arrived? && (step.distance >= peak || step.toward?)
    end

    def one_level_from(step, candidates, levels)
      candidates.select { |candidate| candidate.distance_to(home) == step.distance + levels }.sample(random:)
    end

    def direction_between(previous_distance, distance)
      return :level if distance == previous_distance

      distance > previous_distance ? :away : :toward
    end

    def modulation_between(previous_key, key)
      previous_key.modulate_through([key], random:) unless previous_key.distance_to(key).zero?
    end

    def peak
      farthest = home.farthest_distance
      return farthest if range == :farthest
      return farthest + range if range.negative?

      [range, farthest].min
    end
  end
end
