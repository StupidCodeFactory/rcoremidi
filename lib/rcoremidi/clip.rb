module RCoreMidi

  class Clip

    include RCoreMidi::Registrable

    attr_reader :rythm_sequences, :name

    def initialize(name, &block)
      self.name      = name
      self.rythm_sequences = []
      instance_eval(&block)
    end

    def note(pitch, probabilities)
      rythm_sequences << RythmSequence.new(pitch, probabilities)
    end

    private
    attr_accessor :generator
    attr_writer :rythm_sequences, :name
  end

end
