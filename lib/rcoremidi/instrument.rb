require 'musicalism'

module RCoreMidi

  module DSL

    def live(client)
      self.live = Live.new(client)
    end

    def instrument name, channel, &block
      client.instruments << Instrument.new(name).instance_eval(&block)
    end

    private
    attr_accessor :live
  end

  class InvalidNotName < ArgumentError; end

  class Live

    def initialize(client)
      self.client = client
    end

    private
    attr_accessor :client, :instruments
  end

  class Note

    def initialize(name, velocity = 100)
      validate!(name)
      self.note     = Musicalism::Note.new(name[0..-2], name[-1].to_i)
      self.velocity = velocity
    end

    def to_midi
      [note.to_midi, velocity]
    end

    private

    attr_accessor :note, :velocity

    def validate!(name)
      return true if name.match(/^[A-G]{1}([#b]{0,2})[0-7]{1}$/)
      raise InvalidNotName.new("#{name.to_s} is not a valid note name")
    end
  end

  class Instrument
    attr_reader :channel
    def initialize name, channels
      self.name = name
      self.track = []
      self.channels = Array(channels)
    end

    def add note, probabilities
      track << Note.new(note).to_midi
    end

    private
    attr_accessor :name, :track
    attr_writer :channels
  end


end
