module RCoreMidi

  class Live
    attr_reader :instruments

    def initialize(bpm, clips_dir, instruments_dir, &block)
      self.bpm             = bpm
      self.clips_dir       = clips_dir
      self.instruments_dir = instruments_dir

      load_clips
      load_instruments
    end

    def generate_beats(bar)
      Instrument.all.flat_map do |instrument|
        instrument.generate_bar(bar, duration_calculator)
      end
    end

    private
    attr_accessor :bpm, :clips_dir, :instruments_dir

    def duration_calculator
      @duration_calculator ||= DurationCalculator.new(bpm)
    end

    def load_clips
      Dir["#{clips_dir}/**/*.rb"].each { |file| load file }
    end

    def load_instruments
      Dir["#{instruments_dir}/**/*.rb"].each { |file| load file }
    end

  end
end
