require 'bundler/setup'

Bundler.require :default

class DummyLatest < RCoreMidi::Application
  load_clips!
  load_instruments!
end
