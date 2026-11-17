#include "rcoremidi.h"
#include <dispatch/dispatch.h>
#include <pthread.h>
#include <stdatomic.h>

static MIDIClientRef midi_client;
static bool midi_client_created;
static OSStatus midi_client_creation_status;
static dispatch_semaphore_t midi_client_attempted;
static atomic_bool midi_setup_changed = true;

static bool changes_device_list(MIDINotificationMessageID message) {
  return message == kMIDIMsgSetupChanged || message == kMIDIMsgObjectAdded ||
         message == kMIDIMsgObjectRemoved ||
         message == kMIDIMsgPropertyChanged;
}

static void *serve_midi_notifications(void *unused) {
  midi_client_creation_status = MIDIClientCreateWithBlock(
      CFSTR("rcoremidi"), &midi_client, ^(const MIDINotification *message) {
        if (changes_device_list(message->messageID)) {
          atomic_store(&midi_setup_changed, true);
        }
      });
  bool created = midi_client_creation_status == noErr;
  dispatch_semaphore_signal(midi_client_attempted);
  if (created) {
    CFRunLoopRun();
  }
  return NULL;
}

static OSStatus create_client_on_notification_thread(void) {
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    midi_client_attempted = dispatch_semaphore_create(0);
  });

  pthread_t thread;
  pthread_attr_t attributes;
  pthread_attr_init(&attributes);
  pthread_attr_setdetachstate(&attributes, PTHREAD_CREATE_DETACHED);
  int started =
      pthread_create(&thread, &attributes, serve_midi_notifications, NULL);
  pthread_attr_destroy(&attributes);
  if (started != 0) {
    return kMIDIUnknownError;
  }
  dispatch_semaphore_wait(midi_client_attempted, DISPATCH_TIME_FOREVER);
  return midi_client_creation_status;
}

MIDIClientRef shared_midi_client(void) {
  if (!midi_client_created) {
    raise_on_midi_error(create_client_on_notification_thread(),
                        "Could not create the MIDI client");
    midi_client_created = true;
  }
  return midi_client;
}

bool take_midi_setup_change(void) {
  return atomic_exchange(&midi_setup_changed, false);
}
