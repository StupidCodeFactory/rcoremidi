require 'observer'
require 'rcoremidi/notifier'

module RCoreMidi

  class Clip
    include RCoreMidi::Registrable, Observable

    attr_reader :rythm_sequences, :name, :notifier

    def initialize(name, &block)
      self.name      = name
      self.rythm_sequences = []
    end

    def note(pitch, probabilities)
      self.rythm_sequences << RythmSequence.new(pitch, probabilities)
    end

    def load(&block)
      self.rythm_sequences = []
      changed
      instance_eval(&block)
      notify_observers(self)
    end

    private
    attr_accessor :generator, :block
    attr_writer :rythm_sequences, :name, :notifier

    def log(msg)
      RCoreMidi::Application.config.logger.info msg
    end

  end
end
