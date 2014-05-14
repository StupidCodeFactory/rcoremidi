require 'musicalism'

module RCoreMidi
  class InvalidNotName < ArgumentError; end

  class Live
    attr_reader :instruments_by_channel, :instruments_file

    def initialize(client, instruments_dir)
      self.client = client
      self.instruments_dir = instruments_dir
      self.instruments_by_channel = {}
      self.instruments_file = []
    end

    def instrument name, channels, &block
      file = File.open(File.join(instruments_dir, "#{name}.rb"))
      Array(channels).each do |channel|
        (instruments_by_channel[channel] ||= [])  << Instrument.new(name, channel, file)
      end

    end

    private
    attr_accessor :client, :instruments_dir
    attr_writer :instruments_by_channel, :instruments_file
  end

  class Note
    attr_reader :note, :velocity, :at_offset, :status_byte

    NOTE_ON = 0x90
    NOTE_OFF = 0x80

    def initialize(name, velocity = 100, at_offset = 0)
      validate!(name)
      self.note      = Musicalism::Note.new(name[0..-2], name[-1].to_i)
      self.velocity  = velocity
      self.at_offset = at_offset
      self.status_byte    = 0 | NOTE_ON
    end

    def to_midi_bytes
      [status_byte, note.to_midi, velocity]
    end

    def on(channel)
      self.status_byte = channel | NOTE_ON
      self
    end

    def off(channel)
      self.status_byte = channel | NOTE_OFF
      self
    end

    private
    attr_writer :note, :velocity, :at_offset, :status_byte

    def validate!(name)
      return true if name.match(/^[A-G]{1}([#b]{0,2})[0-7]{1}$/)
      raise InvalidNotName.new("#{name.to_s} is not a valid note name")
    end
  end
  class Generator
    attr_accessor :probabilities,  :generator
    private       :probabilities=, :generator=

    def initialize(probabilities, generator)
      self.probabilities = probabilities
      self.generator    = generator
    end

    def play?(i)
      puts generator.inspect
      generator.nil? ? (probabilities[i] == 1) : (probabilities[i] > generator.call)
    end
  end

  class Instrument
    attr_reader :notes

    def initialize(name, channel, file)
      self.name = name
      self.notes = {}
      self.channel = channel
      self.file = file
    end

    def play(note, probabilities, generator = nil)
      notes[note] = Generator.new(probabilities, generator)
      self
    end

    def generate(factory)
      file.rewind
      instance_eval(file.read)
      notes.map do |note, generator|
        factory.generate(note, generator, channel)
      end
    end

    private
    attr_accessor :name, :channel, :file
    attr_writer :notes
  end

end
