$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
$:.unshift(File.join(File.dirname(__FILE__) + '/../ext/rcoremidi/')) unless
  $:.include?(File.join(File.dirname(__FILE__) + '/../ext/rcoremidi/')) || $:.include?(File.expand_path(File.join(File.dirname(__FILE__) + '/../ext/rcoremidi/')))

puts $:.grep(/rcoremidi/).inspect
require "rcoremidi/connection_manager"
require "rcoremidi/client"
begin
  require 'rcoremidi.bundle'
rescue Exception
ensure

end

module Rcoremidi
  VERSION = '0.0.1'
  
  
  
end