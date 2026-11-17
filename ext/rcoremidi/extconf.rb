require 'mkmf'

$CFLAGS << ' -Wall -Wno-unused-parameter'

have_framework('CoreMIDI')
have_framework('CoreFoundation')
have_framework('CoreAudio')

create_makefile('rcoremidi')
