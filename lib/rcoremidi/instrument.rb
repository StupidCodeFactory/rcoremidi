# frozen_string_literal: true

require 'rcoremidi/track'
require 'observer'

module RCoreMidi
  class Instrument # :nodoc:
    include RCoreMidi::Registrable
    attr_reader :name

    def initialize(name, channel, &block)
      self.name    = name
      self.channel = channel
      self.block   = block
    end

    def generate_beat(current_tick)
      track.bars[current_tick]
    end

    def log(msg)
      RCoreMidi::Application.config.logger.info msg
    end

    def play(bar, clip_name)
      clip = find_clip(clip_name)
      clip.add_observer(self)
      track.play(bar, clip, channel)
    end

    def load
      instance_eval(&block)
    end

    def update(_clip)
      track.reset
      load
    end

    def bar(number)
      track.bars[number]
    end

    private

    attr_accessor :channel, :file, :block
    attr_writer :tracks, :name

    def track
      @track ||= Track.new
    end

    def find_clip(name)
      raise ArgumentError, "Clip #{name} not found." unless clip = Clip[name]
      clip
    end
  end
end
