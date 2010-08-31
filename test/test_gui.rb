require "test/unit"
require File.join(File.expand_path(File.dirname(__FILE__)) + '/test_helper')
class TestRCoremidiExtn < Test::Unit::TestCase
  def setup
    @view = RCoreMidi::GUI::Base.new
  end
  
  def test_it_clear_screen
    @view.clear
    loop do
      trap "SIGINT", proc { exit }
    end
  end
end