#include <stdio.h>
#include <ruby.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreAudio/CoreAudio.h>
#include <CoreMIDI/MIDIServices.h>
#include "MidiQueue.h"
#include "Client.h"
#include "Ports.h"
#include "Source.h"
#include "ConnectionManager.h"
#include "MidiQueue.h"

extern VALUE rb_cConectionManager;
extern VALUE rb_cSource;
extern VALUE rb_cEndpoint;
extern VALUE rb_cClient;
extern VALUE rb_cPort;
extern VALUE rb_cMidiQueue;
