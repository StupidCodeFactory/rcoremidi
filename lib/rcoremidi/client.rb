# frozen_string_literal: true

module RCoreMidi
  class Client # :nodoc:
    attr_accessor :midi_in, :midi_out

    def on_tick(midi_beat_clock)
      puts midi_beat_clock
      # return unless bar_start?(midi_beat_clock)
      byebug
      to_send = live.beats_for(current_tick)
      ap to_send
      send_packets(midi_out, to_send)
    end

    def create_live
      connect!
      self.live = Live.new
      live.load
    end

    private

    attr_accessor :live

    def connect!
      connect_to midi_in
    end
  end
end
