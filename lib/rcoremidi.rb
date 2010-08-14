$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# puts $:.inspect
require "rcoremidi/connection_manager"
require "rcoremidi/client"
begin
  require "../ext/rcoremidi/rcoremidi.bundle" unless require "rcoremidi.bundle" 
rescue LoadError

rescue Eception => e
  puts "Rcore Midi bundle not loaded"
end

module Rcoremidi
  VERSION = '0.0.1'
  
  
  
end