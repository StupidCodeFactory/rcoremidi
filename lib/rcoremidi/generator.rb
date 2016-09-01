module RCoreMidi

  class Generator
    attr_accessor :probabilities,  :generator, :note
    private       :probabilities=, :generator=, :note=

    def initialize(note, probabilities, generator = nil)
      self.probabilities = probabilities
      self.generator     = generator
      self.note          = note
    end

    def generate
      probabilities.map { |p| Note.new(note, 90, on, off, channel) }
    end

    def play?(i)
      generator.nil? ? (probabilities[i] == 1) : (probabilities[i] > generator.call)
    end
  end
end
