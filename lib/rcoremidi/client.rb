module RCoreMidi
  class Client

    def setup
      connect_to RCoreMidi::ConnectionManager.ask_for_connection?
      self
    end

    def on_tick(bar)
      to_send = @live.generate_beats(bar).flatten.compact
      ap to_send
      send_packets(@destination, to_send)
    end

    def start
      trap 'SIGINT', Proc.new {
        dispose
        puts "quiting"
        exit(0)
      }
      sleep
    end

    def live(source, destination, bpm, clips_dir, instruments_dir)
      connect_to source
      @destination = destination
      @live = Live.new(bpm, clips_dir, instruments_dir)
    end

    private

    def duration_calculator
      @duration_calculator ||= DurationCalculator.new(@bpm)
    end

  end
end
