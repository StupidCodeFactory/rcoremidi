module RCoreMidi
  class Note
    attr_accessor :note, :velocity, :channel, :status_byte, :on_timestamp, :off_timestamp
    private :note=, :velocity=, :channel=, :status_byte=, :on_timestamp=

    NOTE_ON  = 0x90
    NOTE_OFF = 0x80

    def initialize(name, on_timestamp = nil, off_timestamp = nil, channel = 0, velocity = 90)
      validate!(name)
      self.note          = Musicalism::Note.new(name[0..-2], name[-1].to_i)
      self.velocity      = velocity
      self.channel       = channel
      self.on_timestamp  = on_timestamp
      self.off_timestamp = off_timestamp
    end

    def on
      [channel | NOTE_ON, note.to_midi, velocity]
    end

    def off
      [channel | NOTE_OFF, note.to_midi, 0]
    end

    private
    attr_writer :note, :velocity, :at_offset, :status_byte

    def validate!(name)
      return true if name.match(/^[A-G]{1}([#b]{0,2})[0-7]{1}$/)
      raise InvalidNotName.new("#{name.to_s} is not a valid note name")
    end
  end
end
