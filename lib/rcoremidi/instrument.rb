require 'rcoremidi/track'
require 'observer'

module RCoreMidi

  class Instrument

    include RCoreMidi::Registrable
    attr_reader :name
    def initialize(name, channel, &block)
      self.name    = name
      self.channel = channel
      instance_eval(&block)
    end

    def generate_bar(bar)
      track.generate(bar)
    end

    def play(bar, clip_name, enable_probability = false)
      ap [bar, clip_name, enable_probability = false]
      clp = clip(clip_name)
      if bar.is_a? Range
        bar.each do |bar_index|
          track.play(bar_index, clp, enable_probability)
        end
        track.reset_at = bar.max
      else
        track.play(bar, clp, enable_probability)
      end
    end

    private

    attr_accessor :channel, :file
    attr_writer :tracks, :name

    def track
      @track ||= Track.new
    end

    def clip(name)
      raise ArgumentError.new("Clip #{name} not found.") unless c = Clip[name]
      c
    end

  end

end
