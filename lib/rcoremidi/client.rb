module RCoreMidi
  class Client
    
    def setup
      connect_to RCoreMidi::ConnectionManager.ask_for_connection?
      @queue = RCoreMidi::MidiQueue.new
      self
    end
    
  end
end