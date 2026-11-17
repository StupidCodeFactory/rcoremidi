require 'observer'
require 'musicalism'
require 'rcoremidi/notifier'

module RCoreMidi
  class Clip
    include Observable
    include RCoreMidi::Registrable

    CHORD_ON_FIRST_STEP = ([1] + [0] * 15).freeze
    MISSING_KEY_MESSAGE = "set the clip key first, e.g. key 'C major'".freeze

    attr_reader :rythm_sequences, :name, :notifier

    def initialize(name)
      self.name = name
      forget_definition
    end

    def key(name = nil)
      return @key if name.nil?

      @key = Musicalism::Key.coerce(name)
    end

    def note(pitch_or_degree, beat_resolution, probabilities)
      rythm_sequences << RythmSequence.new(pitch_name(pitch_or_degree), beat_resolution, probabilities)
    end

    def chord(chord_or_numeral, beat_resolution, probabilities, inversion: 0)
      chord = musicalism_chord(chord_or_numeral, inversion)
      rythm_sequences << RythmSequence.new(pitch_names(chord), beat_resolution, probabilities)
    end

    def modulate(to:, via: nil, beat_resolution: 16, rhythm: CHORD_ON_FIRST_STEP, voice_leading: true)
      self.bars = current_key.modulate_to(to, via: via, voice_leading: voice_leading).map do |chord|
        [RythmSequence.new(pitch_names(chord), beat_resolution, rhythm)]
      end
    end

    def rythm_sequences_for(bar_offset)
      return rythm_sequences if bars.empty?

      rythm_sequences + bars[bar_offset % bars.size]
    end

    def load(&block)
      forget_definition
      changed
      instance_eval(&block)
      notify_observers(self)
    end

    private

    attr_accessor :generator, :block, :bars
    attr_writer :rythm_sequences, :name, :notifier

    def forget_definition
      self.rythm_sequences = []
      self.bars = []
      @key = nil
    end

    def current_key
      key || raise(ArgumentError, MISSING_KEY_MESSAGE)
    end

    def pitch_name(pitch_or_degree)
      pitch_or_degree.is_a?(Integer) ? note_name(current_key.note(pitch_or_degree)) : pitch_or_degree
    end

    def musicalism_chord(chord_or_numeral, inversion)
      return chord_or_numeral.inverse(inversion) if chord_or_numeral.is_a?(Musicalism::Chord)

      current_key.chord(chord_or_numeral, inversion: inversion)
    end

    def pitch_names(chord)
      chord.notes.map { |note| note_name(note) }
    end

    def note_name(note)
      "#{note.pitch}#{note.octave}"
    end

    def log(msg)
      RCoreMidi::Application.config.logger.info msg
    end
  end
end
