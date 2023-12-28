#include "rcoremidi.h"

VALUE rb_mRCOREMIDI;
VALUE rb_cMIDIObject;
VALUE rb_cDevice;
VALUE rb_cEntity;
VALUE rb_cSource;
VALUE rb_cDestination;
VALUE rb_cConectionManager;
VALUE rb_cEndpoint;
VALUE rb_cClient;
VALUE rb_cPort;
VALUE rb_cMidiQueue;
VALUE rb_cMidiPacket;

ID new_intern;
ID devices_intern;
ID empty_intern;
ID lock_intern;
ID length_intern;
ID pack_intern;
ID core_midi_cb_thread_intern;
ID on_intern;
ID off_intern;
ID on_timestamp_intern;
ID off_timestamp_intern;

VALUE rdebug(VALUE rb_obj) {
  rb_funcall(rb_mKernel, (ID)rb_intern("puts"), rb_obj);
  return Qnil;
}

void no_err(const OSStatus status, const char *error_message) {
  if (status != noErr) {
    rb_raise(rb_eRuntimeError, error_message, NULL);
  }
}

void midi_endpoint_free(void *ptr) {
  MIDIEndpointRef *tmp = ptr;
  if (tmp) {
    free(tmp);
  }
}

size_t midi_endpoint_memsize(const void *ptr) {
  return ptr ? sizeof(MIDIEndpointRef) : 0;
}

const rb_data_type_t midi_endpoint_data_t = {
    "midi_enpoint", 0, midi_endpoint_free, midi_endpoint_memsize};

void Init_rcoremidi() {

  new_intern = rb_intern("new");
  devices_intern = rb_intern("@@devices");
  empty_intern = rb_intern("empty?");
  length_intern = rb_intern("length");
  core_midi_cb_thread_intern = rb_intern("@@core_midi_cb_thread");
  on_intern = rb_intern("on");
  off_intern = rb_intern("off");
  on_timestamp_intern = rb_intern("on_timestamp");
  off_timestamp_intern = rb_intern("off_timestamp");

  rb_mRCOREMIDI = rb_define_module("RCoreMidi");

  rb_cMIDIObject =
      rb_define_class_under(rb_mRCOREMIDI, "MIDIObject", rb_cObject);
  rb_define_singleton_method(rb_cMIDIObject, "find_by_unique_id",
                             find_by_unique_id, 1);

  /*
   * RCoreMidi::Device
   */
  rb_cDevice = rb_define_class_under(rb_mRCOREMIDI, "Device", rb_cObject);
  rb_cvar_set(rb_cDevice, devices_intern, rb_ary_new());
  /* rb_cvar_set(rb_cDevice, lock_intern, rb_mutex_new()); */
  rb_define_singleton_method(rb_cDevice, "all", find_all, 0);
  rb_define_alloc_func(rb_cDevice, midi_object_alloc);
  rb_define_attr(rb_cDevice, "name", 1, 0);
  rb_define_attr(rb_cDevice, "driver", 1, 0);
  rb_define_attr(rb_cDevice, "manufacturer", 1, 0);
  rb_define_attr(rb_cDevice, "uid", 1, 0);
  rb_define_attr(rb_cDevice, "entities", 1, 0);

  /*
   * RCoreMidi::Entity
   */
  rb_cEntity = rb_define_class_under(rb_mRCOREMIDI, "Entity", rb_cObject);
  rb_define_alloc_func(rb_cEntity, midi_object_alloc);
  rb_define_attr(rb_cEntity, "uid", 1, 0);
  rb_define_attr(rb_cEntity, "name", 1, 0);
  rb_define_attr(rb_cEntity, "endpoints", 1, 0);

  /*
   * RCoreMidi::Source
   */
  rb_cSource = rb_define_class_under(rb_mRCOREMIDI, "Source", rb_cObject);
  rb_define_alloc_func(rb_cSource, midi_object_alloc);
  rb_define_attr(rb_cSource, "uid", 1, 0);

  /*
   * RCoreMidi::Destination
   */
  rb_cDestination =
      rb_define_class_under(rb_mRCOREMIDI, "Destination", rb_cObject);
  rb_define_alloc_func(rb_cDestination, midi_object_alloc);
  rb_define_attr(rb_cDestination, "uid", 1, 0);

  /*
   * RCoreMidi::Client
   */
  rb_cClient = rb_define_class_under(rb_mRCOREMIDI, "Client", rb_cObject);
  rb_define_alloc_func(rb_cClient, client_alloc);
  rb_define_method(rb_cClient, "initialize", client_init, 1);
  rb_define_method(rb_cClient, "connect_to", connect_to, 1);
  rb_define_method(rb_cClient, "dispose", dispose_client, 0);
  rb_define_method(rb_cClient, "send", x_send, 2);
  rb_define_method(rb_cClient, "send_packets", send_packets, 2);
  rb_define_attr(rb_cClient, "name", 1, 1);
  rb_define_attr(rb_cClient, "is_connected", 1, 1);
}
