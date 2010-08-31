#include <stdio.h>
#include <ruby.h>
#include <Carbon/carbon.h>
#include <CoreAudio/CoreAudio.h>
#include <CoreMIDI/MIDIServices.h>
#include "MidiQueue.h"
#include "Client.h"
#include "Ports.h"
#include "Source.h"
#include "ConnectionManager.h"
#include "MidiPacket.h"
#include "MidiQueue.h"
#include "Timer.h"

extern VALUE rb_cConectionManager;
extern VALUE rb_cSource;
extern VALUE rb_cEndpoint;
extern VALUE rb_cClient;
extern VALUE rb_cPort;
extern VALUE rb_cMidiQueue;
extern VALUE rb_cMidiPacket;
extern VALUE rb_cTimer;

typedef enum MidiStatus MidiStatus;
enum MidiStatus
{
	kMIDISongPositionPointer = 0xF2,
	kMIDITick  	     		 = 0xF8,
	kMIDIStart 	     		 = 0xFA,
	kMIDIContinue    		 = 0xFB,
	kMIDIStop 	     		 = 0xFC
};
