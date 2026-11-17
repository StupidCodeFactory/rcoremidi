#include "rcoremidi.h"

VALUE rb_mRCOREMIDI;
VALUE rb_cMIDIObject;
VALUE rb_cDevice;
VALUE rb_cEntity;
VALUE rb_cSource;
VALUE rb_cDestination;
VALUE rb_cClient;

ID new_intern;
ID devices_intern;
ID on_intern;
ID off_intern;
ID on_timestamp_intern;
ID off_timestamp_intern;
ID on_start_intern;
ID on_tick_intern;
ID on_stop_intern;
ID on_continue_intern;

void raise_on_midi_error(OSStatus status, const char *message) {
  if (status != noErr) {
    rb_raise(rb_eRuntimeError, "%s (OSStatus %d)", message, (int)status);
  }
}

static VALUE host_time_now(VALUE module) {
  return ULL2NUM(AudioGetCurrentHostTime());
}

static VALUE host_time_to_nanoseconds(VALUE module, VALUE host_time) {
  return ULL2NUM(AudioConvertHostTimeToNanos(NUM2ULL(host_time)));
}

static VALUE host_time_from_nanoseconds(VALUE module, VALUE nanoseconds) {
  return ULL2NUM(AudioConvertNanosToHostTime(NUM2ULL(nanoseconds)));
}

static void init_host_time(void) {
  VALUE host_time = rb_define_module_under(rb_mRCOREMIDI, "HostTime");
  rb_define_singleton_method(host_time, "now", host_time_now, 0);
  rb_define_singleton_method(host_time, "to_nanoseconds",
                             host_time_to_nanoseconds, 1);
  rb_define_singleton_method(host_time, "from_nanoseconds",
                             host_time_from_nanoseconds, 1);
}

static VALUE define_midi_object_class(const char *name) {
  VALUE klass = rb_define_class_under(rb_mRCOREMIDI, name, rb_cObject);
  rb_define_alloc_func(klass, midi_object_alloc);
  rb_define_attr(klass, "uid", 1, 0);
  return klass;
}

void Init_rcoremidi(void) {
  new_intern = rb_intern("new");
  devices_intern = rb_intern("@@devices");
  on_intern = rb_intern("on");
  off_intern = rb_intern("off");
  on_timestamp_intern = rb_intern("on_timestamp");
  off_timestamp_intern = rb_intern("off_timestamp");
  on_start_intern = rb_intern("on_start");
  on_tick_intern = rb_intern("on_tick");
  on_stop_intern = rb_intern("on_stop");
  on_continue_intern = rb_intern("on_continue");

  rb_mRCOREMIDI = rb_define_module("RCoreMidi");
  init_host_time();
  init_universal_packet(rb_mRCOREMIDI);

  rb_cMIDIObject =
      rb_define_class_under(rb_mRCOREMIDI, "MIDIObject", rb_cObject);
  rb_define_singleton_method(rb_cMIDIObject, "find_by_unique_id",
                             find_by_unique_id, 1);

  rb_cDevice = define_midi_object_class("Device");
  rb_cvar_set(rb_cDevice, devices_intern, rb_ary_new());
  rb_define_singleton_method(rb_cDevice, "all", find_all, 0);
  rb_define_attr(rb_cDevice, "name", 1, 0);
  rb_define_attr(rb_cDevice, "driver", 1, 0);
  rb_define_attr(rb_cDevice, "manufacturer", 1, 0);
  rb_define_attr(rb_cDevice, "entities", 1, 0);

  rb_cEntity = define_midi_object_class("Entity");
  rb_define_attr(rb_cEntity, "name", 1, 0);
  rb_define_attr(rb_cEntity, "endpoints", 1, 0);

  rb_cSource = define_midi_object_class("Source");
  rb_cDestination = define_midi_object_class("Destination");

  rb_cClient = rb_define_class_under(rb_mRCOREMIDI, "Client", rb_cObject);
  rb_define_alloc_func(rb_cClient, client_alloc);
  rb_define_method(rb_cClient, "initialize", client_init, 1);
  rb_define_method(rb_cClient, "connect_to", connect_to, 1);
  rb_define_method(rb_cClient, "start", start_client, 0);
  rb_define_method(rb_cClient, "stop", stop_client, 0);
  rb_define_method(rb_cClient, "running?", client_running, 0);
  rb_define_method(rb_cClient, "silence", silence_client, 0);
  rb_define_method(rb_cClient, "dropped_clock_events", dropped_clock_events,
                   0);
  rb_define_method(rb_cClient, "dispose", dispose_client, 0);
  rb_define_method(rb_cClient, "send_packets", send_packets, -1);
  rb_define_attr(rb_cClient, "name", 1, 0);
}
