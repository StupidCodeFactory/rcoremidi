# frozen_string_literal: true

require 'observer'
require 'rcoremidi/notifier'

module RCoreMidi
  class Clip # :nodoc:
    include Observable
    include RCoreMidi::Registrable

    attr_reader :rythm_sequences, :name, :notifier

    def initialize(name)
      self.name = name
      self.rythm_sequences = []
    end

    def note(pitch, rhythm_pattern)
      rhythm_pattern = RythmSequence.new(pitch, rhythm_pattern)
      rhythm_pattern.generate.each do |note, i|
        beats[i] << note if note
      end
    end

    def load(&block)
      self.rythm_sequences = []
      changed
      instance_eval(&block)
      notify_observers(self)
    end

    def beats
      @notes ||= Array.new(96) { [] }
    end

    private

    attr_accessor :generator, :block
    attr_writer :rythm_sequences, :name, :notifier

    def log(msg)
      RCoreMidi::Application.config.logger.info msg
    end
  end
end
