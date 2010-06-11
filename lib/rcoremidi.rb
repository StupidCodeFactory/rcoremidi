$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# require "../ext/rcoremidircoremidi.bundle"
module Rcoremidi
  VERSION = '0.0.1'
end