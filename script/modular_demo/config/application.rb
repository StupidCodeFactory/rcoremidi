require 'bundler/setup'

Bundler.require :default

class ModularDemo < RCoreMidi::Application
  load_clips!
  load_instruments!
end
