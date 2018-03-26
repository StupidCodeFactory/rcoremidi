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
      track.generate(current_tick)
    end

    def log(msg)
      RCoreMidi::Application.config.logger.info msg
    end

    def play(bar, clip_name, enable_probability = false)
      clp = clip(clip_name)
      clp.add_observer(self)
      if bar.is_a? Range
        bar.each do |bar_index|
          track.play(bar_index, clp, enable_probability)
        end
        track.reset_at = bar.max
      else
        track.play(bar, clp, enable_probability)
      end
    end

    def load
      instance_eval(&block)
    end

    def update(_clip)
      track.reset
      load
    end

    private

    attr_accessor :channel, :file, :block
    attr_writer :tracks, :name

    def track
      @track ||= Track.new(channel)
    end

    def clip(name)
      raise ArgumentError, "Clip #{name} not found." unless c = Clip[name]
      c
    end
  end
end
