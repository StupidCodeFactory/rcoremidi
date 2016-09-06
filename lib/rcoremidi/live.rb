module RCoreMidi

  class Live
    attr_reader :instruments

    def initialize(bpm, instruments_dir)
      self.bpm             = bpm
      self.instruments_dir = instruments_dir
      self.instruments     = []
    end

    def load_instrument name, channel
      puts "Loading instrument: #{name} on channel: #{channel}"
      file = File.open(File.join(instruments_dir, "#{name}.rb"))
      instruments << Instrument.new(name, channel, file)
    end

    def generate_beats(bar)
      instruments.flat_map do |instrument|
        instrument.generate_tracks(bar, duration_calculator)
      end
    end

    private
    attr_accessor :bpm, :instruments_dir, :instruments

    def duration_calculator
      @duration_calculator ||= DurationCalculator.new(bpm)
    end
  end
end
