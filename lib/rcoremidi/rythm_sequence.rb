require 'rcoremidi/probability_generator'

module RCoreMidi
  class RythmSequence
    attr_reader :pitches, :probabilities

    def initialize(pitch, beat_resolution, probabilities, velocities = nil)
      self.pitches         = Array(pitch)
      self.beat_resolution = beat_resolution
      self.probabilities   = probabilities
      self.velocities      = velocities
    end

    def generate(enable_probability, channel)
      probabilities.each_with_index.flat_map do |probability, step|
        next [] unless probability_generator[enable_probability].play?(probability)

        timestamps = duration_calculator.timestamps_for(step)
        pitches.map { |pitch| Note.new(pitch, *timestamps, channel, velocity_at(step)) }
      end
    end

    private

    attr_writer :pitches, :probabilities
    attr_accessor :beat_resolution, :velocities

    def velocity_at(step)
      velocities ? velocities[step % velocities.size] : Note::DEFAULT_VELOCITY
    end

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
