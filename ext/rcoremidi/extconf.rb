require 'mkmf'

$CFLAGS   = "-Wno-error=shorten-64-to-32 -g"
$CPPFLAGS += " -g "
$CPPFLAGS += "-I/Users/yann/.rbenv/versions/2.1.1/include/ruby-2.1.0 -I/System/Library/Frameworks/CoreMIDI.framework/Headers "
$LDFLAGS  += " -F/System/Library/Frameworks  -framework CoreMIDI -framework CoreFoundation -framework CoreAudio -framework Carbon"
dir_config("rcoremidi")
create_makefile("rcoremidi")
