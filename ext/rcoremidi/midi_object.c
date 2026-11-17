#include "rcoremidi.h"

static size_t midi_object_memsize(const void *ptr) {
  return sizeof(MIDIObjectRef);
}

const rb_data_type_t midi_object_data_t = {
    "rcoremidi_object",
    {NULL, RUBY_TYPED_DEFAULT_FREE, midi_object_memsize},
    NULL,
    NULL,
    RUBY_TYPED_FREE_IMMEDIATELY};

VALUE midi_object_alloc(VALUE klass) {
  MIDIObjectRef *midi_object;
  return TypedData_Make_Struct(klass, MIDIObjectRef, &midi_object_data_t,
                               midi_object);
}

MIDIObjectRef *get_midi_data(VALUE rb_midi_object) {
  MIDIObjectRef *midi_object;
  TypedData_Get_Struct(rb_midi_object, MIDIObjectRef, &midi_object_data_t,
                       midi_object);
  return midi_object;
}

static VALUE wrap_midi_object(VALUE klass, MIDIObjectRef midi_object) {
  VALUE object = rb_funcall(klass, new_intern, 0);
  *get_midi_data(object) = midi_object;
  return object;
}

static VALUE string_property(MIDIObjectRef midi_object, CFStringRef key) {
  CFStringRef value = NULL;
  if (MIDIObjectGetStringProperty(midi_object, key, &value) != noErr ||
      !value) {
    return Qnil;
  }
  CFIndex capacity = CFStringGetMaximumSizeForEncoding(CFStringGetLength(value),
                                                       kCFStringEncodingUTF8) +
                     1;
  VALUE buffer_owner;
  char *buffer = ALLOCV(buffer_owner, capacity);
  Boolean converted =
      CFStringGetCString(value, buffer, capacity, kCFStringEncodingUTF8);
  CFRelease(value);
  VALUE result = converted ? rb_utf8_str_new_cstr(buffer) : Qnil;
  ALLOCV_END(buffer_owner);
  return result;
}

static bool integer_property(MIDIObjectRef midi_object, CFStringRef key,
                             SInt32 *value) {
  return MIDIObjectGetIntegerProperty(midi_object, key, value) == noErr;
}

static void set_string_ivar(VALUE object, const char *ivar,
                            MIDIObjectRef midi_object, CFStringRef key) {
  VALUE value = string_property(midi_object, key);
  if (!NIL_P(value)) {
    rb_iv_set(object, ivar, value);
  }
}

static void set_integer_ivar(VALUE object, const char *ivar,
                             MIDIObjectRef midi_object, CFStringRef key) {
  SInt32 value;
  if (integer_property(midi_object, key, &value)) {
    rb_iv_set(object, ivar, INT2NUM(value));
  }
}

static void set_boolean_ivar(VALUE object, const char *ivar,
                             MIDIObjectRef midi_object, CFStringRef key) {
  SInt32 value;
  if (integer_property(midi_object, key, &value)) {
    rb_iv_set(object, ivar, value ? Qtrue : Qfalse);
  }
}

static void assign_endpoint_properties(VALUE endpoint,
                                       MIDIEndpointRef midi_endpoint) {
  set_integer_ivar(endpoint, "@uid", midi_endpoint, kMIDIPropertyUniqueID);
  set_string_ivar(endpoint, "@name", midi_endpoint, kMIDIPropertyName);
}

static void assign_entity_properties(VALUE entity, MIDIEntityRef midi_entity) {
  set_integer_ivar(entity, "@uid", midi_entity, kMIDIPropertyUniqueID);
  set_string_ivar(entity, "@name", midi_entity, kMIDIPropertyName);
  set_integer_ivar(entity, "@protocol", midi_entity, kMIDIPropertyProtocolID);
  set_integer_ivar(entity, "@receive_channels", midi_entity,
                   kMIDIPropertyReceiveChannels);
  set_boolean_ivar(entity, "@receives_notes", midi_entity,
                   kMIDIPropertyReceivesNotes);
}

static void assign_device_properties(VALUE device, MIDIDeviceRef midi_device) {
  set_integer_ivar(device, "@uid", midi_device, kMIDIPropertyUniqueID);
  set_string_ivar(device, "@name", midi_device, kMIDIPropertyName);
  set_string_ivar(device, "@model", midi_device, kMIDIPropertyModel);
  set_string_ivar(device, "@manufacturer", midi_device,
                  kMIDIPropertyManufacturer);
  set_string_ivar(device, "@driver", midi_device, kMIDIPropertyDriverOwner);
  set_integer_ivar(device, "@schedule_ahead_micro_seconds", midi_device,
                   kMIDIPropertyAdvanceScheduleTimeMuSec);
  set_integer_ivar(device, "@transmit_channels", midi_device,
                   kMIDIPropertyTransmitChannels);
  set_integer_ivar(device, "@receives_channels", midi_device,
                   kMIDIPropertyReceiveChannels);
  set_boolean_ivar(device, "@supports_general_midi", midi_device,
                   kMIDIPropertySupportsGeneralMIDI);
  set_boolean_ivar(device, "@supports_mmc", midi_device,
                   kMIDIPropertySupportsMMC);
  set_boolean_ivar(device, "@receives_clock", midi_device,
                   kMIDIPropertyReceivesClock);
  set_boolean_ivar(device, "@receives_mtc", midi_device,
                   kMIDIPropertyReceivesMTC);
  set_boolean_ivar(device, "@offline", midi_device, kMIDIPropertyOffline);
  set_boolean_ivar(device, "@transmits_mtc", midi_device,
                   kMIDIPropertyTransmitsMTC);
  set_boolean_ivar(device, "@transmits_clock", midi_device,
                   kMIDIPropertyTransmitsClock);
}

static VALUE build_endpoint(VALUE klass, MIDIEndpointRef midi_endpoint) {
  VALUE endpoint = wrap_midi_object(klass, midi_endpoint);
  assign_endpoint_properties(endpoint, midi_endpoint);
  return endpoint;
}

static VALUE build_entity(VALUE device, MIDIEntityRef midi_entity) {
  VALUE entity = wrap_midi_object(rb_cEntity, midi_entity);
  VALUE endpoints = rb_ary_new();
  rb_iv_set(entity, "@endpoints", endpoints);
  rb_iv_set(entity, "@device", device);
  assign_entity_properties(entity, midi_entity);

  ItemCount sources = MIDIEntityGetNumberOfSources(midi_entity);
  for (ItemCount i = 0; i < sources; ++i) {
    rb_ary_push(endpoints,
                build_endpoint(rb_cSource, MIDIEntityGetSource(midi_entity, i)));
  }
  ItemCount destinations = MIDIEntityGetNumberOfDestinations(midi_entity);
  for (ItemCount i = 0; i < destinations; ++i) {
    rb_ary_push(endpoints, build_endpoint(rb_cDestination,
                                          MIDIEntityGetDestination(midi_entity,
                                                                   i)));
  }
  return entity;
}

static VALUE build_device(MIDIDeviceRef midi_device) {
  VALUE device = wrap_midi_object(rb_cDevice, midi_device);
  VALUE entities = rb_ary_new();
  rb_iv_set(device, "@entities", entities);
  assign_device_properties(device, midi_device);

  ItemCount entity_count = MIDIDeviceGetNumberOfEntities(midi_device);
  for (ItemCount i = 0; i < entity_count; ++i) {
    rb_ary_push(entities,
                build_entity(device, MIDIDeviceGetEntity(midi_device, i)));
  }
  return device;
}

VALUE find_by_unique_id(VALUE klass, VALUE uid) {
  MIDIObjectRef midi_object;
  MIDIObjectType midi_object_type;
  OSStatus status = MIDIObjectFindByUniqueID((MIDIUniqueID)NUM2INT(uid),
                                             &midi_object, &midi_object_type);
  if (status != noErr) {
    rb_raise(rb_eArgError, "MIDI object not found: %d", NUM2INT(uid));
  }

  switch (midi_object_type) {
  case kMIDIObjectType_Device:
    return build_device(midi_object);
  case kMIDIObjectType_Entity:
    return build_entity(Qnil, midi_object);
  case kMIDIObjectType_Source:
    return build_endpoint(rb_cSource, midi_object);
  case kMIDIObjectType_Destination:
    return build_endpoint(rb_cDestination, midi_object);
  default:
    rb_raise(rb_eArgError, "Unsupported MIDI object type for uid %d",
             NUM2INT(uid));
  }
}

static VALUE build_devices(void) {
  VALUE devices = rb_ary_new();
  ItemCount device_count = MIDIGetNumberOfDevices();
  for (ItemCount i = 0; i < device_count; ++i) {
    rb_ary_push(devices, build_device(MIDIGetDevice(i)));
  }
  return devices;
}

VALUE find_all(VALUE klass) {
  shared_midi_client();
  VALUE devices = rb_cvar_get(klass, devices_intern);
  if (take_midi_setup_change() || RARRAY_LEN(devices) == 0) {
    devices = build_devices();
    rb_cvar_set(klass, devices_intern, devices);
  }
  return devices;
}
