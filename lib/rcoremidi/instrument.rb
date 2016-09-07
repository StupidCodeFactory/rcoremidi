require 'musicalism'

module RCoreMidi
  class InvalidNotName < ArgumentError; end

  class Instrument

    include RCoreMidi::Registrable

    def initialize(name, channel, &block)
      self.name    = name
      self.channel = channel
    end


    def generate_tracks(bar, duration_calculator)
      reload.tracks.map do |track|
        track.generate(bar, duration_calculator)
      end.reduce(:+)
    end

    def play(bar, clip)
      track[bar] = clip
    end

    private
    attr_accessor :name, :channel, :file
    attr_writer :tracks

    def tracks
      @tracks ||= {}
    end
  end

end
