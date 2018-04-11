# frozen_string_literal: true

require 'rcoremidi/notifier'

module RCoreMidi
  class Track # :nodoc:
    attr_accessor :reset_at, :clips, :channel

    def play(bar, clip, channel = 0)
      if bars[bar].nil?
        clip.beats.each { |notes| notes.each { |note| note.channel = channel } }
        bars[bar] = clip.beats
      else
        bars[bar].each_with_index do |existing_notes, i|
          clip.beats[i].each { |note| note.channel = channel }
          existing_notes |= clip.beats[i]
        end
      end
    end

    def bars
      @bars ||= {}
    end

    def reset
      @bars = {}
    end
    private

    attr_accessor :notifiers
  end
end
