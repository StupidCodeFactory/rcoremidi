module RCoreMidi
  class Client

    attr_reader :instruments

    def setup
      connect_to RCoreMidi::ConnectionManager.ask_for_connection?
      self
    end

    def on_tick
      puts "called on tick"
    end

    def start
      trap 'SIGINT', proc { puts "quiting"; exit(0) }

      loop do
        sleep 10
      end

    end

  end
end
