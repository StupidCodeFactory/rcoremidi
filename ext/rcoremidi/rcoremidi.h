#include <Carbon/carbon.h>
#include <CoreAudio/CoreAudio.h>
#include <CoreMIDI/MIDIServices.h>
#include <mach/mach_time.h>
#include <pthread.h>
#include <ruby.h>
#include <ruby/thread.h>
#include <stdbool.h>
#include <stdio.h>

#include "client.h"
#include "midi_object.h"

extern VALUE rb_cConectionManager;
extern VALUE rb_cDevice;
extern VALUE rb_cEntity;
extern VALUE rb_cSource;
extern VALUE rb_cDestination;
extern VALUE rb_cEndpoint;
extern VALUE rb_cClient;

extern ID on_tick; /* TODO: remove? */
extern ID new_intern;
extern ID devices_intern;
extern ID empty_intern;
extern ID lock_intern;
extern ID length_intern;
extern ID pack_intern;
extern ID on_intern;
extern ID off_intern;
extern ID on_timestamp_intern;
extern ID off_timestamp_intern;

extern const rb_data_type_t midi_endpoint_data_t;
extern const rb_data_type_t midi_object_data_t;

typedef struct callback_t {
  pthread_mutex_t mutex;
  pthread_cond_t cond;

  struct callback_t *next;
  void *data;
  bool handled;
} callback_t;

extern pthread_mutex_t g_callback_mutex;
extern pthread_cond_t g_callback_cond;
extern callback_t *g_callback_queue;

typedef struct callback_waiting_t {
  callback_t *callback;
  bool abort;
} callback_waiting_t;

typedef struct midi_send_params_t {
  MIDIPortRef *out;
  MIDIEndpointRef *midi_destination;
  Byte *data;
  ByteCount data_size;

} midi_send_params_t;

typedef struct RCoremidiNode {
  MIDIClientRef *client;
  char *name;
  MIDIPortRef *in;
  MIDIPortRef *out;
  RCoreMidiTransport *transport;
  VALUE rb_client_obj;
  callback_t *callback;
} RCoremidiNode;

typedef enum MidiStatus MidiStatus;
enum MidiStatus {
  kMIDISongPositionPointer = 0xF2,
  kMIDITick = 0xF8,
  kMIDIStart = 0xFA,
  kMIDIContinue = 0xFB,
  kMIDIStop = 0xFC
};

typedef enum MidiState MidiState;
enum MidiState { kMIDIStarted = 0, kMIDIStoped = 1 };

void no_err(const OSStatus status, const char *error_message);
void midi_endpoint_free(void *ptr);
size_t midi_endpoint_memsize(const void *ptr);

void g_callback_queue_push(callback_t *callback);
RCoremidiNode *client_get_data(VALUE self);

VALUE rdebug(VALUE rb_obj);
