require "test/unit"
require File.dirname(__FILE__) + '/test_helper.rb'


class TestRcoremidi < Test::Unit::TestCase


  def setup
      @client =  RCoreMidi::Client.new("test name").setup
      puts @client.inspect
  end

  
  def test_can_instanciate_ConectionManager
    # puts @conn_pool.inspect
    # puts "-----------------"
    # puts @chosen_connection.inspect
    # assert_instance_of Proc, @conn_pool
  end
end
