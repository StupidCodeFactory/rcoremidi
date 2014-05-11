require 'musicalism'

module RCoreMidi
  class InvalidNotName < ArgumentError; end

  class Live

    def initialize(client)
      self.client = client
      self.instruments = []
    end

    def instrument name, channel, &block
      instruments << Instrument.new(name, channel).instance_eval(&block)
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

    def initialize(name, channels)
      self.name = name
      self.notes = []
      self.channels = Array(channels)
    end

    def add(note, probabilities)
      notes << Note.new(note)
    end

    private
    attr_accessor :name, :notes, :channels
  end

end
