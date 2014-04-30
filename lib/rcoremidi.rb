$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
# $:.unshift(File.join(File.dirname(__FILE__) + '/../ext/rcoremidi/')) unless
#   $:.include?(File.join(File.dirname(__FILE__) + '/../ext/rcoremidi/')) || $:.include?(File.expand_path(File.join(File.dirname(__FILE__) + '/../ext/rcoremidi/')))

# $:.unshift(File.join(File.dirname(__FILE__) + '/../tmp/x86_64-darwin13.0/stage/lib/'))



require 'rcoremidi.bundle'

require "rcoremidi/connection_manager"
require "rcoremidi/client"
require "rcoremidi/instrument"
require "rcoremidi/gui/base"
