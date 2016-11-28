require 'rcoremidi/probability_generator'

module RCoreMidi

  class RythmSequence
    def initialize(pitch, probabilities)
      self.pitch         = pitch
      self.probabilities = probabilities
    end

    def generate(enable_probability)
      probabilities.map.with_index do |probability, i|
        next unless probability_generator[enable_probability].play?(probability)

        Note.new(pitch, *duration_calculator.timestamps_for(i))
      end
    end

    private
    attr_accessor :pitch, :probabilities

    def probability_generator
      @probability_generator ||= {
        false => ProbabilityGenerator.new,
        true  => ProbabilityGenerator.new { SecureRandom.random_number }
      }
    end

    def duration_calculator
      @duration_calculator ||= DurationCalculator.new(RCoreMidi::Application.config.bpm)
    end
  end

end
