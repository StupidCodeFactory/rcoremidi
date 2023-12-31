module RCoreMidi
  class Client
    attr_accessor :midi_in, :midi_out

    def on_start; end

    def on_tick(tick)
      self.bar += 1 if (tick % 96).zero?
      to_send = live.generate_beats(bar).flatten.compact
      pp to_send
      send_packets(midi_out, to_send)
    end

    def create_live
      connect!
    end

    def live
      @live ||= Live.new
    end

    private

    attr_writer :bar

    def connect!
      connect_to midi_in
    end

    def bar
      @bar ||= 0
    end
  end
end
