require 'musicalism'

module RCoreMidi
  class InvalidNotName < ArgumentError; end

  class Instrument

    def initialize(name, channel, file)
      self.name    = name
      self.channel = channel
      self.file    = file
    end

    def play(pitch, probabilities, probability_generator: nil)
      puts "Loading track for #{pitch}"
      self.tracks << Track.new(pitch, probabilities, ProbabilityGenerator.new(&probability_generator))
      self
    end

    def generate_tracks(duration_calculator)
      reload.tracks.map do |track|
        track.generate(duration_calculator)
      end.reduce(:+)
    end

    def reload
      file.rewind
      self.tracks = []
      instance_eval(file.read)
      self
    end

    def tracks
      @tracks ||= []
    end

    private
    attr_accessor :name, :channel, :file
    attr_writer :tracks
  end

end
