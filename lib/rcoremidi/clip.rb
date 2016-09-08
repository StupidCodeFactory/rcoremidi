module RCoreMidi

  class Clip

    include RCoreMidi::Registrable

    attr_reader :notes

    def initialize(name, &block)
      self.name      = name
      self.notes     = []
      self.generator = block
    end

    def call
      instance_eval(&generator)
    end

    def note(pitch, probabilities)
      notes << RythmSequence.new(pitch, probabilities)
    end

    private
    attr_accessor :generator, :name
    attr_writer :notes
  end

end
