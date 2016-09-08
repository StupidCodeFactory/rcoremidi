module RCoreMidi
  class Client

    def setup
      connect_to RCoreMidi::ConnectionManager.ask_for_connection?
      self
    end

    def on_tick(bar)
      to_send = @live.generate_beats.flatten.compact
      send_packets(@destination, to_send)
    end

    def start
      @flag = 0
      trap 'SIGINT', Proc.new {
        dispose
        puts "quiting"
        exit(0)
      }
      sleep
    end

    def live(source, destination, bpm, instruments_dir)
      connect_to source
      @destination = destination
      @live = Live.new(bpm, instruments_dir)
    end

    private

    def duration_calculator
      @duration_calculator ||= DurationCalculator.new(@bpm)
    end

  end
end
