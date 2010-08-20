require "test/unit"
require File.dirname(__FILE__) + '/test_helper.rb'


class TestRCoremidi < Test::Unit::TestCase

  def setup
      @client = RCoreMidi::Client.new("test name").setup
  end

  
  def test_client_has_dispose_method
    assert_respond_to @client, :dispose
  end
  
  def test_client_can_start
    assert_respond_to @client, :start
  end
  
  
  def test_client_can_be_disposed
    assert_nothing_raised do 
      @client.dispose
    end
  end
  
  def test_can_start
    @client.start
  end
end
