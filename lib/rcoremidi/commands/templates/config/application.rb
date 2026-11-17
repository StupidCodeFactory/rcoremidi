require 'bundler/setup'

Bundler.require :default

class <%= app_const %> < RCoreMidi::Application
  load_clips!
  load_instruments!
end
