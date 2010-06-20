$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# puts $:.inspect
require "rcoremidi/connection_manager"
require "rcoremidi/client"
begin
  require "rcoremidi.bundle"
rescue
  require "../ext/rcoremidi/rcoremidi.bundle"  
ensure
  puts "Rcore Midi bundle not laoded"
end

module Rcoremidi
  VERSION = '0.0.1'
  
  
  
end