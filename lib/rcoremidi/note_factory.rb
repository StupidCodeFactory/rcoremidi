module RCoreMidi

  class NoteFactory
    def initialize(probabilities, duration_calculator)
      self.duration_calculator = duration_calculator
      self.probabilities       = probabilities
    end

    def generate(pitch)
      probabilities.each_with_index.map do |probability, i|
        next if (probability && (probability <= 0)) || probability.nil?
        on, off = duration_calculator.timestamps_for(i)
        Note.new(pitch, on, off)
      end.compact
    end

    private
    attr_accessor :duration_calculator, :probabilities
  end
end
