#ifndef RCOREMIDI_H
#define RCOREMIDI_H

#include <CoreAudio/HostTime.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreMIDI/CoreMIDI.h>
#include <ruby.h>
#include <ruby/thread.h>
#include <stdbool.h>

#include "client.h"
#include "midi_client.h"
#include "midi_object.h"
#include "universal_packet.h"

extern VALUE rb_cDevice;
extern VALUE rb_cEntity;
extern VALUE rb_cSource;
extern VALUE rb_cDestination;
extern VALUE rb_cClient;

extern ID new_intern;
extern ID devices_intern;
extern ID on_intern;
extern ID off_intern;
extern ID on_timestamp_intern;
extern ID off_timestamp_intern;
extern ID on_start_intern;
extern ID on_tick_intern;
extern ID on_stop_intern;
extern ID on_continue_intern;

extern const rb_data_type_t midi_object_data_t;

void raise_on_midi_error(OSStatus status, const char *message);

#endif
