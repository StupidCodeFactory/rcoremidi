require 'rcoremidi/duration_calculator'

module RCoreMidi

  class Live
    attr_reader :instruments

    def generate_beats(current_tick)
      Instrument.all.flat_map do |instrument|
        instrument.generate_beat(current_tick)
      end
    end

  end
end
