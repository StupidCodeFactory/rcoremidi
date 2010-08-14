# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rcoremidi}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Yann Marquet"]
  s.date = %q{2010-08-14}
  s.description = %q{This is a ruby extension to provide a wrapper for
the osx CoreMidi Framework}
  s.email = ["ymarquet@gmail.com"]
  s.extensions = ["ext/rcoremidi/extconf.rb"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt"]
  s.files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "ext/rcoremidi/rcoremidi.c", "ext/rcoremidi/Base.h", "ext/rcoremidi/Client.c", "ext/rcoremidi/Client.h", "ext/rcoremidi/ConnectionManager.c", "ext/rcoremidi/ConnectionManager.h", "ext/rcoremidi/extconf.rb", "ext/rcoremidi/MidiPacket.c", "ext/rcoremidi/MidiPacket.h", "ext/rcoremidi/MidiQueue.c", "ext/rcoremidi/MidiQueue.h", "ext/rcoremidi/NotificationProcs.c", "ext/rcoremidi/NotificationProcs.h", "ext/rcoremidi/Ports.c", "ext/rcoremidi/Ports.h", "ext/rcoremidi/Source.c", "ext/rcoremidi/Source.h", "ext/rcoremidi/Timer.c", "ext/rcoremidi/Timer.h", "lib/rcoremidi.rb", "lib/rcoremidi/connection_manager.rb", "lib/rcoremidi/client.rb", "script/console", "script/destroy", "script/generate", "test/test_helper.rb", "test/test_rcoremidi.rb", "test/test_rcoremidi_extn.rb", "test/test_rcoremidi_live_midi.rb"]
  s.homepage = %q{http://github.com/yannmarquet/rcoremidi}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib", "ext/rcoremidi"]
  s.rubyforge_project = %q{rcoremidi}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{This is a ruby extension to provide a wrapper for the osx CoreMidi Framework}
  s.test_files = ["test/test_helper.rb", "test/test_rcoremidi.rb", "test/test_rcoremidi_extn.rb", "test/test_rcoremidi_live_midi.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_development_dependency(%q<hoe>, [">= 2.6.1"])
    else
      s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_dependency(%q<hoe>, [">= 2.6.1"])
    end
  else
    s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
    s.add_dependency(%q<hoe>, [">= 2.6.1"])
  end
end
