require 'mkmf'

$CFLAGS = '-Wno-error=shorten-64-to-32 -fobjc-arc -fmodules'
# $CPPFLAGS += ' -g '
# $CPPFLAGS += '-I/Users/yann/.rbenv/versions/2.1.1/include/ruby-2.1.0 -I/System/Library/Frameworks/CoreMIDI.framework/Headers '
# $LDFLAGS += ' -F/System/Library/Frameworks  -framework CoreMIDI -framework CoreFoundation -framework Foundation -framework CoreAudio -framework Carbon'
# $LDFLAGS += ' -F/System/Library/Frameworks  -framework CoreMIDI -framework CoreFoundation -framework Foundation -framework CoreAudio -framework Carbon'

have_framework('CoreMIDI')
have_framework('CoreFoundation')
have_framework('Foundation')
have_framework('CoreAudio')
have_framework('Carbon')

dir_config('rcoremidi')
create_makefile('rcoremidi')
