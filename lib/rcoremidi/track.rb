module RCoreMidi

  class Track
    def initialize(pitch, probabilities, probability_generator)
      self.pitch         = pitch
      self.probabilities = probabilities
      self.probabiltiy_generator = probability_generator
    end

    def generate(duration_calculator)
      probabilities.map.with_index do |probability, i|

        next unless probabiltiy_generator.play?(probability)

        Note.new(pitch, *duration_calculator.timestamps_for(i))
      end
    end

    private
    attr_accessor :pitch, :probabilities, :probabiltiy_generator

  end
end
