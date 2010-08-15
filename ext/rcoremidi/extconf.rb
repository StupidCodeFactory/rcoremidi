require 'mkmf'

$CPPFLAGS += "-I/System/Library/Frameworks/Ruby.framework/Headers/ -I/System/Library/Frameworks/CoreMIDI.framework/Headers"
$LDFLAGS += "-framework Ruby -framework CoreMIDI -framework CoreFoundation -framework CoreAudio -framework Carbon"
dir_config("rcoremidi")

create_makefile("rcoremidi")
