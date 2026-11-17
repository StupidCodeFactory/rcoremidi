require 'observer'
require 'rcoremidi/notifier'

module RCoreMidi
  class Clip
    include Observable
    include RCoreMidi::Registrable

    attr_reader :rythm_sequences, :name, :notifier

    def initialize(name)
      self.name            = name
      self.rythm_sequences = []
    end

    # def note(pitch, beat_resolution, probabilities: nil)

    #   rythm_sequences << RythmSequence.new(pitch, beat_resolution, probabilities)
    # end

    def note(pitch, note_ons)
      note_ons.map {|note_on| note_one > 0 ? Note.new : Note.new}
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
