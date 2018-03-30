# frozen_string_literal: true

require 'rcoremidi/notifier'

module RCoreMidi
  class Track # :nodoc:
    attr_accessor :reset_at, :clips, :channel
    PPQN = 96

    def initialize(channel)
      self.reset_at = 0
      self.channel = channel
    end

    def generate(current_tick)

      puts current_tick
      # if current_tick == reset_at
      #   return @clips = {} && []
      # end
      bar = current_tick / PPQN
      clip, enable_probability = bars[bar]

      return [] unless clip
      clip.rythm_sequences.map do |rythm_sequence|
        rythm_sequence.generate(enable_probability, channel).compact
      end.inject(:+)
    end

    def play(bar, clip, enable_probability)
      bars[bar] = [clip, enable_probability]
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
