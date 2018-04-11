# frozen_string_literal: true

require 'rcoremidi/duration_calculator'

module RCoreMidi
  class Live # :nodoc:
    attr_reader :instruments

    PPQN = 24

    def beats_for(current_tick)
      beats[current_tick]
    end

    def load(current_bar = 1)
      beats.each_with_index do |beat, i|
        Instrument.all.each do |instrument|

          instrument_beats = instrument.bar(current_bar)
          begin
            beat << instrument_beats[i] unless instrument_beats[i].empty?
          rescue
            byebug
          end
        end
      end
    end

    def beats
      @beats ||= Array.new(96) { [] }
    end
  end
end
