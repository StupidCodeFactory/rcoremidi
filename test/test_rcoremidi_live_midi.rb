require "test/unit"
require File.dirname(__FILE__) + '/test_helper.rb'


class TestRcoremidi < Test::Unit::TestCase


  def setup
      @client =  RCoreMidi::Client.new("test name").setup
      puts @client.inspect
  end

  
  def test_client_has_dispose_method
    puts @client.methods.sort.inspect
    assert @client.respond_to? "dispose"
  end
end
