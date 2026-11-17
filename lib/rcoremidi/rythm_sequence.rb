require 'rcoremidi/probability_generator'

module RCoreMidi
  class RythmSequence
    attr_reader :pitches, :probabilities

    def initialize(pitch, beat_resolution, probabilities)
      self.pitches         = Array(pitch)
      self.beat_resolution = beat_resolution
      self.probabilities   = probabilities
    end

    def generate(enable_probability, channel)
      probabilities.each_with_index.flat_map do |probability, step|
        next [] unless probability_generator[enable_probability].play?(probability)

        timestamps = duration_calculator.timestamps_for(step)
        pitches.map { |pitch| Note.new(pitch, *timestamps, channel) }
      end
    end

    private

    attr_writer :pitches, :probabilities
    attr_accessor :beat_resolution

    def probability_generator
      @probability_generator ||= {
        false => ProbabilityGenerator.new,
        true => ProbabilityGenerator.new { SecureRandom.random_number }
      }
    end

    def duration_calculator
      @duration_calculator ||= DurationCalculator.new(RCoreMidi::Application.config.bpm)
    end
  end
end
