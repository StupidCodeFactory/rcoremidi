require 'bundler/setup'

Bundler.require :default

class ClockCheck < RCoreMidi::Application
  load_clips!
  load_instruments!
end
