require "test/unit"
require File.dirname(__FILE__) + '/test_helper.rb'


class TestRcoremidi < Test::Unit::TestCase


  def setup
      @client =  RCoreMidi::Client.new("test name").setup
  end

  
  def test_client_has_dispose_method
    assert @client.respond_to? "dispose"
  end
end
