require 'rcoremidi/notifier'

module RCoreMidi
  class Track
    attr_accessor :channel

    def initialize(channel)
      self.channel = channel
    end

    def generate(bar)
      clip, enable_probability, bar_offset = bars[bar]

      return [] unless clip

      clip.rythm_sequences_for(bar_offset).flat_map do |rythm_sequence|
        rythm_sequence.generate(enable_probability, channel)
      end
    end

    def play(bar, clip, enable_probability, bar_offset = 0)
      bars[bar] = [clip, enable_probability, bar_offset]
    end

    def reset
      @bars = {}
    end

    private

    attr_accessor :notifiers

    def bars
      @bars ||= {}
    end
  end
end
