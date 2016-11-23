require 'bundler/setup'

Bundler.require :default

class <%= app_const %> < RCoreMidi::Application
end
