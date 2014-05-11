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
      trap 'SIGINT', Proc.new {
        dispose
        puts "quiting"
        exit(0)
      }
      @@core_midi_cb_thread.join
    end

    def live(&block)
      @live = Live.new(self)
      @live.instance_eval(&block)
    end

  end
end
