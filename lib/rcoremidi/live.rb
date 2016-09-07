module RCoreMidi

  class Live
    attr_reader :instruments

    def initialize(bpm, clips_dir)
      self.bpm         = bpm
      self.clips_dir   = clips_dir
      self.instruments = []
    end

    def clip(name)
      Clip[name]
    end

    def load_clips
      Dir["#{clips_dir}/**/*.rb"].each { |file| load file }
    end

    def load_instrument name, channel
      puts "Loading instrument: #{ s name} on channel: #{channel}"
      file = File.open(File.join(instruments_dir, "#{name}.rb"))
      instruments << Instrument.new(name, channel, file)
    end

    def generate_beats(bar)
      instruments.flat_map do |instrument|
        instrument.generate_tracks(bar, duration_calculator)
      end
    end

    private
    attr_accessor :bpm, :clips_dir, :instruments

    def duration_calculator
      @duration_calculator ||= DurationCalculator.new(bpm)
    end
  end
end
