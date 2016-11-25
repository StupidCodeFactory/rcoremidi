# -*- encoding: utf-8 -*-
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'rcoremidi/version'
Gem::Specification.new do |s|
  s.name = %q{rcoremidi}
  s.version = RCoreMidi::VERSION
  s.authors = ['StupidCodeFactory <ymarquet@gmail.com>']
  s.date = %q{2010-08-14}
  s.description = %q{This is a ruby extension to provide a wrapper for
the osx CoreMidi Framework}
  s.email = ["ymarquet@gmail.com"]
  s.extensions = ["ext/rcoremidi/extconf.rb"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt"]
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{http://github.com/yannmarquet/rcoremidi}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib", "ext/rcoremidi"]
  s.rubyforge_project = %q{rcoremidi}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{This is a ruby extension to provide a wrapper for the osx CoreMidi Framework}
  s.test_files = Dir['spec/**/*.rb']

  s.add_dependency 'thor'
  s.add_dependency 'listen'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'aruba'
  s.add_development_dependency 'rake-compiler'
end
