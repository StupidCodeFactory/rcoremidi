module RCoreMidi

  class Clip

    include RCoreMidi::Registrable

    def initialize(name, &block)
      self.name      = name
      self.notes     = []
      self.generator = block
    end

    def call
      instance_eval(&generator)
    end

    def note(pitch, probabilities, probability_generator: nil, mutator: nil)
      notes << RythmSequence.new(pitch, probabilities, ProbabilityGenerator.new(&probability_generator), mutator)
    end

    private
    attr_accessor :notes, :generator, :name
  end

end
