# require "test/unit"
# require "test_helper"
# 
# 
# class TestRcoremidiExtn < Test::Unit::TestCase
#   def setup
#     @conn_manager = RCoreMidi::ConectionManager.devices
#   end
#   
#   def test_can_return_array_of_sources
#     puts @conn_manager.inspect
#     assert_instance_of Proc, @conn_manager, "Wrong class instance" 
#   end
#   
#   def test_assert_sources_array_filled_with_a_data_property_of_class_Endpoint
#     @conn_manager.map do |i,s| 
#       assert_not_nil s.instance_variable_get('@data'), "Should have not been nil"
#       assert_instance_of RCoreMidi::Endpoint, s.instance_variable_get('@data'),  "Should be RCoreMidi::Enpoint, anyway received #{s.class}"
#     end
#   end
#   
#   def test_assert_can_instanciate_Client_class
#     client = RCoreMidi::Client.new "toto"
#     assert_instance_of RCoreMidi::Client, client,  "Should be RCoreMidi::Client, anyway received #{client.class}"
#   end
#   
#   def test_assert_can_instanciate_Client_class_with_client_name_as_argument
#     client = RCoreMidi::Client.new "name"
#     assert_equal client.name, "name", "name is wrong"
#   end
#   
#   def test_assert_not_equal_wrong_name
#     client = RCoreMidi::Client.new "name"
#     assert_not_equal client.name, "qsdsdname", "name is wrong"
#   end
#   
#   def test_assert_can_change_client_name
#     client = RCoreMidi::Client.new "name"
#     client.name = "Test_client"
#     assert_equal client.name, "Test_client", "Client name attirubute could not be changed"
#   end
#   
#   def test_assert_client_has_input_instance_variable
#     client = RCoreMidi::Client.new "name"
#     assert_not_nil client.input, "Client has no input port"
#   end
#   
#   def test_assert_client_has_output_instance_variable
#     client = RCoreMidi::Client.new "name"
#     assert_not_nil client.output, "Client has no output port"
#   end
#   
#   def test_assert_client_has_client_ref_instance_variable
#     client = RCoreMidi::Client.new "name"
#     assert_not_nil client.instance_variable_get("@client_ref"), "Client has no client_ref instance variable"
#   end
#   
#   def test_assert_client_as_source_attrinute_and_initialised_to_nil
#     client = RCoreMidi::Client.new "name"
#     assert_nil client.source
#   end
# 
#   def test_client_connect_source
#     client = RCoreMidi::Client.new("nfor_connection")
#     client.connect_to(@conn_manager[1])
#   end
#   
#   
#   def test_can_instanciate_MidiQueue
#       queue = RCoreMidi::MidiQueue.new
#       puts queue.inspect
#       assert_not_nil queue
#   end
#   
#   def test_assert_can_instanciate_Timer_class
#     timer = RCoreMidi::Timer.new 180
#     puts timer.inspect
#   end
#   
#   def test_can_change_tempo
#     timer = RCoreMidi::Timer.new 180
#     timer.tempo = 120
#     assert_equal timer.tempo, 120
#   end
#   
#   def test_assert_create_port
#     assert_instance_of RCoreMidi::Port, RCoreMidi::Port.new
#   end
#   
#   def test_assert_port_as_port_ref_attribute
#     assert_not_nil RCoreMidi::Port.new.port_ref
#   end
# 
#   # def test_timer_responds_to_start
#   #   assert_equal true, RCoreMidi::Timer.new(180).start
#   # end
#   # 
#   # def test_Timer_can_start
#   #   assert_equal true, RCoreMidi::Timer.new(180).start
#   # end
#       
# end