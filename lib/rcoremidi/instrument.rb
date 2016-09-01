require 'musicalism'

module RCoreMidi
  class InvalidNotName < ArgumentError; end

  class Instrument
    attr_reader :track, :channel

    def initialize(name, channel, file)
      self.name    = name
      self.track   = {}
      self.channel = channel
      self.file    = file
    end

    def play(note, probabilities, generator = nil)
      track[note] = probabilities
      self
    end

    def reload
      file.rewind
      instance_eval(file.read)
      self
    end

    private
    attr_accessor :name, :channel, :file
    attr_writer :track


  end

end
