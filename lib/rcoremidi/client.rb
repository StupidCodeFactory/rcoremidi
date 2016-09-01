module RCoreMidi
  class Client

    def setup
      connect_to RCoreMidi::ConnectionManager.ask_for_connection?
      self
    end

    def on_tick
      to_send = @live.generate_beats(duration_calculator).flatten.compact
      ap to_send
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

    def live(destination, instruments_dir, &block)
      @destination = destination
      @live = Live.new(instruments_dir)
      @live.instance_eval(&block)
    end

    private

    def duration_calculator
      @duration_calculator ||= DurationCalculator.new(@bpm)
    end

  end
end
