module RCoreMidi
  class Client
    
    def setup
      RCoreMidi::ConnectionManager.devices.inspect
      connect_to RCoreMidi::ConnectionManager.ask_for_connection?
      @queue = RCoreMidi::MidiQueue.new
    end
    
  end
end