require 'musicalism'

module RCoreMidi
  class InvalidNotName < ArgumentError; end

  class Instrument
    attr_reader :notes

    def initialize(name, channel, file)
      self.name    = name
      self.notes   = {}
      self.channel = channel
      self.file    = file
    end

    def play(note, probabilities, generator = nil)
      notes[note] = Generator.new(probabilities, generator)
      self
    end

    def generate(factory)
      file.rewind
      instance_eval(file.read)
      notes.inject([]) do |acc, note_and_generator|
        note, generator = note_and_generator
        acc += factory.generate(note, generator, channel)
        acc
      end
    end

    private
    attr_accessor :name, :channel, :file
    attr_writer :notes
  end

end
