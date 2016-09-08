module RCoreMidi

  class RythmSequence
    def initialize(pitch, probabilities)
      self.pitch         = pitch
      self.probabilities = probabilities
    end

    def generate(duration_calculator, enable_probability)
      probabilities.map.with_index do |probability, i|

        next unless probabiltiy_generator(enable_probability).play?(probability)

        Note.new(pitch, *duration_calculator.timestamps_for(i))
      end
    end

    private
    attr_accessor :pitch, :probabilities

    def probabiltiy_generator(enable_probability)
      @probabiltiy_generator ||= ProbabilityGenerator.new
    end
  end

end
