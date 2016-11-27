require 'observer'
require 'rcoremidi/notifier'

module RCoreMidi

  class Clip
    include RCoreMidi::Registrable, Observable

    attr_reader :rythm_sequences, :name, :notifier

    def initialize(name, &block)
      self.name      = name
      self.rythm_sequences = []
      self.block = block
      self.notifier = Notifier.new(self)
      add_observer(notifier)
    end

    def note(pitch, probabilities)
      RCoreMidi::Application.config.logger.info "called #{pitch}"
      rythm_sequences << RythmSequence.new(pitch, probabilities)
    end

    def load
      rythm_sequences.clear
      instance_eval(&block)
      changed
      notify_observers(self)
    end

    private
    attr_accessor :generator, :block
    attr_writer :rythm_sequences, :name, :notifier
  end

end
