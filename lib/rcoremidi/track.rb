require 'rcoremidi/notifier'

module RCoreMidi

  class Track
    attr_accessor :reset_at, :clips
    def initialize
      self.reset_at = 0
    end

    def generate(bar)
      if bar == reset_at
        return @clips = {} && []
      end

      clip, enable_probability = clips[bar]

      return [] unless clip

      clip.rythm_sequences.map do |rythm_sequence|
        rythm_sequence.generate(enable_probability).compact
      end.inject(:+)
    end

    def play(bar, clip, enable_probability)
      clips[bar] = [clip, enable_probability]
    end

    private
    attr_accessor :notifiers
    def clips
      @clips ||= {}
    end

  end
end
