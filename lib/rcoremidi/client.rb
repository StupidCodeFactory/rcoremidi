# frozen_string_literal: true

module RCoreMidi
  class Client # :nodoc:

    def on_tick(m)
      # return unless bar_start?(midi_beat_clock)
      to_send = live.beats_for(m)
      ap "m: #{m}"
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

    def pool
      @pool ||= Concurrent::CachedThreadPool.new
    end
  end
end
