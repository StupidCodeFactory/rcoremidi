require 'musicalism'

module RCoreMidi
  class InvalidNotName < ArgumentError; end

  class Instrument

    def initialize(name, channel, file)
      self.name    = name
      self.channel = channel
      self.file    = file
    end

    def define_track(name, pitch, probability_generator: nil, mutator: nil)
      puts "Loading patterns #{name} for #{pitch}"
      midi_tracks[name] = Track.new(pitch, probabilities, ProbabilityGenerator.new(&probability_generator), mutator)
    end

    def generate_tracks(bar, duration_calculator)
      reload.tracks.map do |track|
        track.generate(bar, duration_calculator)
      end.reduce(:+)
    end

    def reload
      file.rewind
      self.midi_tracks = {}
      instance_eval(file.read)
      self
    end

    def tracks
      @tracks ||= []
    end

    private
    attr_accessor :name, :channel, :file
    attr_writer :tracks

    def midi_tracks
      @midi_tracks ||= {}
    end
  end

end
