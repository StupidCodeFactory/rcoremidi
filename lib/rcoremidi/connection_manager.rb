module RCoreMidi

  class ConnectionManager

      def self.ask_for_connection?
        devices = RCoreMidi::ConnectionManager.devices
        raise "No device found\n" if devices.nil?

        print "Connect to:\n"
        devices.each { |index, device| puts "\t#{index}) #{device.name}\n" }
        print "connection: [default: 1] => "


        while STDIN.gets != '\n' do
          c = $_.chop.to_i
          return devices[1] unless devices.keys.include? c
          return devices[c]
        end
      end


    def test_methd
      retrun "tested"
    end
    
    
    
  end  
    
end

