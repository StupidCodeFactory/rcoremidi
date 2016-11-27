module RCoreMidi
  class Client

    attr_accessor :midi_in, :midi_out

    def on_tick(bar)
      to_send = live.generate_beats(bar).flatten.compact
      send_packets(midi_out, to_send)
    end

    def create_live
      connect!
      self.live = Live.new
    end

    private
    attr_accessor :live

    def connect!
      connect_to midi_in
    end

  end
end
