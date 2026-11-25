require_relative 'lib/rcoremidi/version'

Gem::Specification.new do |s|
  s.name = 'rcoremidi'
  s.version = RCoreMidi::VERSION
  s.authors = ['Yann Marquet']
  s.email = ['ymarquet@gmail.com']
  s.license = 'MIT'
  s.homepage = 'https://github.com/StupidCodeFactory/rcoremidi'
  s.summary = 'Ruby bindings for the macOS CoreMIDI framework'
  s.description = <<~DESC
    A C extension wrapping macOS CoreMIDI: list MIDI devices, entities, sources
    and destinations, follow an external MIDI clock (Start, Clock, Stop,
    Continue, Song Position) through hooks on a Client subclass, and schedule
    timestamped notes with CoreMIDI's host-time scheduler. macOS only.
  DESC
  s.metadata = {
    'homepage_uri' => s.homepage,
    'changelog_uri' => "#{s.homepage}/blob/master/History.txt"
  }

  s.required_ruby_version = '>= 3.2'
  s.files = Dir.chdir(__dir__) { `git ls-files -z -- lib ext README.md`.split("\x0") }
  s.extensions = ['ext/rcoremidi/extconf.rb']
  s.require_paths = ['lib', 'ext/rcoremidi']
  s.rdoc_options = ['--main', 'README.md']
  s.extra_rdoc_files = ['README.md']

  s.add_development_dependency 'rake-compiler', '~> 1.2'
  s.add_development_dependency 'rdoc', '>= 6', '< 9'
  s.add_development_dependency 'rspec', '~> 3.13'
  s.add_development_dependency 'rspec-its', '~> 2.0'
end
