require 'mkmf'

$CFLAGS   = "-Wno-error=shorten-64-to-32 -g"
$CPPFLAGS += " -g "
$CPPFLAGS += "-I/System/Library/Frameworks/CoreMIDI.framework/Headers "
$LDFLAGS  += " -F/System/Library/Frameworks  -framework CoreMIDI -framework CoreFoundation -framework CoreAudio -framework Carbon"
dir_config("rcoremidi")
create_makefile("rcoremidi")
