require 'bundler/setup'

Bundler.require :default

class JourneyDemo < RCoreMidi::Application
  load_clips!
  load_instruments!
end
