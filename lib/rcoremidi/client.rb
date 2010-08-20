module RCoreMidi
  class Client
    
    def setup
      connect_to RCoreMidi::ConnectionManager.ask_for_connection?
      @queue = RCoreMidi::MidiQueue.new
      self
    end
    
    def start
      loop do
        trap 'SIGINT', proc { puts "quiting"; exit(0) }
      end
      
    end
    
  end
end