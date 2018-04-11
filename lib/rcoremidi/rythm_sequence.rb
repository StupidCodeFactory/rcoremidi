# frozen_string_literal: true

require 'rcoremidi/probability_generator'

module RCoreMidi
  class RythmSequence # :nodoc:

    PULSE_PER_BAR = 96

    def initialize(pitch, probabilities, rhythm =  probabilities.size)
      self.pitch         = pitch
      self.delta         = PULSE_PER_BAR / rhythm
      self.probabilities = probabilities
    end

    def generate
      probabilities.map.with_index do |probability, i|
        next [nil, i] if probability.zero?
          # probability_generator[enable_probability].play?(probability)

        [Note.new(pitch, *duration_calculator.timestamps_for(i), nil), delta * i]
      end
    end

    private

    attr_accessor :pitch, :probabilities, :delta

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
