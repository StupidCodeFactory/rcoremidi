require 'rcoremidi/duration_calculator'

module RCoreMidi

  class Live
    attr_reader :instruments

    def initialize(bpm)
      self.bpm = bpm
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
  end
end
