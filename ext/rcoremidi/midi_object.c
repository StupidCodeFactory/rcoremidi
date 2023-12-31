#include "rcoremidi.h"
#import "test.h"
#include <AssertMacros.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreMIDI/CoreMIDI.h>
#include <MacTypes.h>
#include <ruby.h>
#include <stdio.h>
#include <string.h>

static void midi_object_free(void *ptr) { free(ptr); }
static OSStatus get_integer_properties(MIDIObjectRef *midi_object,
                                       const char *property,
                                       SInt32 *midi_property);
static OSStatus get_string_properties(MIDIObjectRef *midi_object,
                                      const char *property,
                                      CFStringRef *midi_property);

static size_t midi_object_memsize(const void *ptr) {

  return ptr ? sizeof(MIDIObjectRef) : 0;
}

const rb_data_type_t midi_object_data_t = {
    "midi_node", {0, midi_object_free, midi_object_memsize}};

VALUE midi_object_alloc(VALUE klass) {
  MIDIObjectRef *device_ref = malloc(sizeof(MIDIObjectRef));
  return TypedData_Make_Struct(klass, MIDIObjectRef, &midi_object_data_t,
                               device_ref);
}

static void set_uid_from_properties(CFPropertyListRef *midi_properties,
                                    CFNumberRef *uniqueID, SInt64 *uid) {
  *uniqueID = CFDictionaryGetValue(*midi_properties, CFSTR("uniqueID"));
  CFNumberGetValue(*uniqueID, CFNumberGetType(*uniqueID), uid);
}

static void assign_endpoint_properties(VALUE source,
                                       MIDIEndpointRef *midi_object) {

  CFPropertyListRef midi_properties;
  MIDIObjectGetProperties(*midi_object, &midi_properties, true);

  CFNumberRef uniqueID;
  SInt64 uid;
  set_uid_from_properties(&midi_properties, &uniqueID, &uid);

  rb_iv_set(source, "@uid", INT2FIX(uid));
}

MIDIObjectRef *get_midi_data(VALUE rb_midi_object) {
  MIDIObjectRef *midi_object;
  TypedData_Get_Struct(rb_midi_object, MIDIObjectRef, &midi_object_data_t,
                       midi_object);
  return midi_object;
}

static VALUE add_destination_to_entity(VALUE entity, VALUE endpoints,
                                       ItemCount count);
static VALUE add_source_to_entity(VALUE entity, VALUE endpoints,
                                  ItemCount count);
static VALUE add_entites_to_device(VALUE device, VALUE entities,
                                   ItemCount count);

static VALUE create_entity() {
  VALUE entity = rb_funcall(rb_cEntity, new_intern, 0);
  rb_iv_set(entity, "@endpoints", rb_ary_new());
  return entity;
}

static VALUE create_device() {
  VALUE device = rb_funcall(rb_cDevice, new_intern, 0);
  rb_iv_set(device, "@entities", rb_ary_new());
  return device;
}

static VALUE add_destination_to_entity(VALUE entity, VALUE endpoints,
                                       ItemCount count) {
  VALUE destination = rb_funcall(rb_cDestination, new_intern, 0);

  MIDIEndpointRef *midi_destination = get_midi_data(destination);

  *midi_destination = MIDIEntityGetDestination(*get_midi_data(entity), count);

  assign_endpoint_properties(destination, midi_destination);

  rb_ary_push(endpoints, destination);

  if (count == 0) {
    return endpoints;
  } else {
    count--;
    return add_destination_to_entity(entity, endpoints, count);
  }
}

static VALUE add_source_to_entity(VALUE entity, VALUE endpoints,
                                  ItemCount count) {

  VALUE source = rb_funcall(rb_cSource, new_intern, 0);

  MIDIEndpointRef *midi_source = get_midi_data(source);
  *midi_source = MIDIEntityGetSource(*get_midi_data(entity), count);

  assign_endpoint_properties(source, midi_source);

  rb_ary_push(endpoints, source);
  if (count == 0) {
    return endpoints;
  } else {
    count--;
    return add_source_to_entity(entity, endpoints, count);
  }
}

static void assign_entity_properties(VALUE entity, MIDIEntityRef *midi_object) {
  CFPropertyListRef midi_properties;
  MIDIObjectGetProperties(*midi_object, &midi_properties, true);

  CFStringRef cf_name =
      CFDictionaryGetValue(midi_properties, kMIDIPropertyName);
  CFNumberRef uniqueID =
      CFDictionaryGetValue(midi_properties, kMIDIPropertyUniqueID);
  CFStringRef cf_protocol_key = CFStringCreateWithCString(
      kCFAllocatorDefault, "protocol", kCFStringEncodingUTF8);
  CFNumberRef cf_protocol =
      CFDictionaryGetValue(midi_properties, cf_protocol_key);
  long long uid;
  long long protocol;
  CFNumberGetValue(uniqueID, CFNumberGetType(uniqueID), &uid);

  const char *name = NSSTringToCString((void *)cf_name);
  if (name) {
    rb_iv_set(entity, "@name", rb_str_new2(name));
  } else {
    fprintf(stderr, "Could not find name for entity %s\n", name);
  }

  if (CFNumberGetValue(cf_protocol, CFNumberGetType(cf_protocol), &protocol)) {
    rb_iv_set(entity, "@protocol", LONG2NUM(protocol));
  }

  const CFNumberRef receiveChannels;
  int channels;
  if (CFDictionaryGetValueIfPresent(midi_properties,
                                    kMIDIPropertyReceiveChannels,
                                    (void *)&receiveChannels)) {
    if (CFNumberGetValue(receiveChannels, CFNumberGetType(receiveChannels),
                         &channels)) {
      rb_iv_set(entity, "@receive_channels", INT2FIX(channels));
    }
  }

  const CFNumberRef receiveNotes;
  int notes;
  if (CFDictionaryGetValueIfPresent(midi_properties, kMIDIPropertyReceivesNotes,
                                    (void *)&receiveNotes)) {
    CFNumberType type = CFNumberGetType(receiveNotes);
    if (CFNumberGetValue(receiveNotes, CFNumberGetType(receiveNotes),
                         &channels)) {
      rb_iv_set(entity, "@receives_notes", INT2FIX(notes));
    }
  }
  rb_iv_set(entity, "@uid", LONG2NUM(uid));
}

static VALUE add_entites_to_device(VALUE device, VALUE entities,
                                   ItemCount count) {
  VALUE entity = create_entity();
  MIDIEntityRef *midi_entity = get_midi_data(entity);

  *midi_entity = MIDIDeviceGetEntity(*get_midi_data(device), count);

  assign_entity_properties(entity, midi_entity);

  ItemCount destination_or_source_count =
      MIDIEntityGetNumberOfSources(*midi_entity);
  if (destination_or_source_count > 0) {
    add_source_to_entity(entity, rb_iv_get(entity, "@endpoints"),
                         destination_or_source_count - 1);
    rb_iv_set(entity, "@device", device);
  }

  destination_or_source_count = MIDIEntityGetNumberOfDestinations(*midi_entity);
  if (destination_or_source_count > 0) {
    add_destination_to_entity(entity, rb_iv_get(entity, "@endpoints"),
                              destination_or_source_count - 1);
  }

  rb_ary_push(rb_iv_get(device, "@entities"), entity);

  if (count == 0) {
    return entities;
  } else {
    count--;
    return add_entites_to_device(device, entities, count);
  }
}

static OSStatus get_integer_properties(MIDIObjectRef *midi_object,
                                       const char *property,
                                       SInt32 *midi_property) {
  OSStatus error;
  CFStringRef cf_property = CFStringCreateWithCString(
      kCFAllocatorDefault, property, kCFStringEncodingUTF8);

  error =
      MIDIObjectGetIntegerProperty(*midi_object, cf_property, midi_property);
  CFRelease(cf_property);

  return error;
}

static OSStatus get_string_properties(MIDIObjectRef *midi_object,
                                      const char *property,
                                      CFStringRef *midi_property) {
  OSStatus error;
  CFStringRef cf_property = CFStringCreateWithCString(
      kCFAllocatorDefault, property, kCFStringEncodingUTF8);
  error = MIDIObjectGetStringProperty(*midi_object, cf_property, midi_property);

  CFRelease(cf_property);
  return error;
}

static void log_warning(OSStatus error, const char *customMessage) {
  CFStringRef errorMessage = SecCopyErrorMessageString(error, NULL);
  fprintf(stderr, "%s - %s\n",
          CFStringGetCStringPtr(errorMessage, kCFStringEncodingUTF8),
          customMessage);
  CFRelease(errorMessage);
}

static void assign_device_properties(VALUE device, MIDIDeviceRef *midi_device) {
  OSStatus error;
  CFPropertyListRef midi_properties;

  CFStringRef model;
  CFStringRef name;
  CFStringRef driver;
  CFStringRef manufacturer;

  SInt32 uniqueID;
  SInt32 scheduleAheadMuSec;
  SInt32 transmitChannels;
  SInt32 receiveChannels;

  SInt32 supportsGeneralMIDI; /* 'supports General MIDI'.freeze, */
  SInt32 supportsMMC;         /* : 'supports MMC'.freeze, */
  SInt32 receivesClock;       /* : 'receives clock'.freeze, */
  SInt32 receivesMTC;         /* : 'receives MTC'.freeze, */
  SInt32 offline;             /* : 'offline'.freeze, */
  SInt32 transmitsMTC;        /* : 'transmits MTC'.freeze, */
  SInt32 transmitsClock;      /* : 'transmits clock'.freeze */

  error = get_string_properties(midi_device, "model", &model);
  const char *c_str_model = CFStringGetCStringPtr(model, kCFStringEncodingUTF8);
  if (!error && c_str_model) {
    rb_iv_set(device, "@model", rb_str_new2(c_str_model));
  }

  error = get_string_properties(midi_device, "name", &name);
  const char *c_str_name = CFStringGetCStringPtr(name, kCFStringEncodingUTF8);
  if (!error) {
    if (!c_str_name) {
      // some device name are NSString for some reason so try to get
      // the name from the bridge function
      c_str_name = NSSTringToCString((void *)name);
    }
    if (c_str_name) {
      rb_iv_set(device, "@name", rb_str_new2(c_str_name));
    }
  }

  error = get_string_properties(midi_device, "driver", &driver);
  const char *c_str_driver =
      CFStringGetCStringPtr(driver, kCFStringEncodingUTF8);
  if (!error && c_str_driver) {
    rb_iv_set(device, "@driver", rb_str_new2(c_str_driver));
  }

  error = get_integer_properties(midi_device, "uniqueID", &uniqueID);
  if (!error) {
    rb_iv_set(device, "@uniqueID", INT2NUM((int)uniqueID));
  } else {
    printf("uniqueID\n");
    log_warning(error, "property: uniqueID");
  }

  error = get_integer_properties(midi_device, "scheduleAheadMuSec",
                                 &scheduleAheadMuSec);
  if (!error) {
    rb_iv_set(device, "@schedule_ahead_micro_seconds",
              INT2NUM((int)scheduleAheadMuSec));
  }

  error = get_integer_properties(midi_device, "transmitChannels",
                                 &transmitChannels);
  if (!error) {
    rb_iv_set(device, "@transmit_channels", INT2NUM((int)transmitChannels));
  }

  error =
      get_integer_properties(midi_device, "receiveChannels", &receiveChannels);
  if (!error) {
    rb_iv_set(device, "@receives_channels", INT2NUM((int)receiveChannels));
  }

  error = get_integer_properties(midi_device, "supports General MIDI",
                                 &supportsGeneralMIDI);
  if (!error) {
    rb_iv_set(device, "@supports_general_midi",
              (Boolean)supportsGeneralMIDI ? Qtrue : Qfalse);
  }

  error = get_integer_properties(midi_device, "supports General MIDI",
                                 &supportsMMC);
  if (!error) {
    rb_iv_set(device, "@supports_mmc", (Boolean)supportsMMC ? Qtrue : Qfalse);
  }

  error = get_integer_properties(midi_device, "receives clock", &receivesClock);
  if (!error) {
    rb_iv_set(device, "@receives_clock",
              (Boolean)receivesClock ? Qtrue : Qfalse);
  }

  error = get_integer_properties(midi_device, "receives MTC", &receivesMTC);
  if (!error) {
    rb_iv_set(device, "@receives_mtc", (Boolean)receivesMTC ? Qtrue : Qfalse);
  }

  error = get_integer_properties(midi_device, "offline", &offline);
  if (!error) {
    rb_iv_set(device, "@offline", (Boolean)offline ? Qtrue : Qfalse);
  }

  error = get_integer_properties(midi_device, "transmits MTC", &transmitsMTC);
  if (!error) {
    rb_iv_set(device, "@transmits_mtc", (Boolean)transmitsMTC ? Qtrue : Qfalse);
  }

  error =
      get_integer_properties(midi_device, "transmits clock", &transmitsClock);
  if (!error) {
    rb_iv_set(device, "@transmits_clock",
              (Boolean)transmitsClock ? Qtrue : Qfalse);
  }
}

VALUE
find_by_unique_id(VALUE klass, VALUE uid) {

  /* TODO: check for NULL pointer */
  MIDIObjectRef midi_object;
  MIDIObjectType midi_object_type;

  OSStatus error;
  error = MIDIObjectFindByUniqueID((MIDIUniqueID)FIX2INT(uid), &midi_object,
                                   &midi_object_type);

  if (error == kMIDIObjectNotFound) {
    rb_raise(rb_eArgError, "MIDI Object not found %d\n", FIX2INT(uid));
  }

  if (midi_object_type == kMIDIObjectType_Device) {
    VALUE device = create_device();
    *get_midi_data(device) = midi_object;
    assign_device_properties(device, &midi_object);
    return device;
  } else if (midi_object_type == kMIDIObjectType_Entity) {
    VALUE entity = create_entity();
    *get_midi_data(entity) = midi_object;
    assign_entity_properties(entity, &midi_object);
    return entity;
  } else if (midi_object_type == kMIDIObjectType_Source) {
    VALUE source = rb_funcall(rb_cSource, new_intern, 0);
    *get_midi_data(source) = midi_object;
    assign_endpoint_properties(source, &midi_object);
    return source;
  } else if (midi_object_type == kMIDIObjectType_Destination) {
    VALUE destination = rb_funcall(rb_cDestination, new_intern, 0);
    *get_midi_data(destination) = midi_object;
    assign_endpoint_properties(destination, &midi_object);
    return destination;
  } else {
    rb_raise(rb_eArgError, "MIDI Object not found %d\n", FIX2INT(uid));
    return Qnil;
  }
}

static VALUE get_devices(VALUE devices, ItemCount count) {
  VALUE device = create_device();
  MIDIDeviceRef *midi_device = get_midi_data(device);
  *midi_device = MIDIGetDevice(count);

  assign_device_properties(device, midi_device);

  rb_ary_push(devices, device);

  ItemCount entities_count = MIDIDeviceGetNumberOfEntities(*midi_device);

  if (entities_count > 0) {
    add_entites_to_device(device, rb_iv_get(device, "@entities"),
                          entities_count - 1);
  }

  if (count == 0) {
    return devices;
  } else {
    count--;
    return get_devices(devices, count);
  }
}

static void populate_devices(VALUE klass) {
  VALUE devices = rb_cvar_get(klass, devices_intern);
  ItemCount device_count = MIDIGetNumberOfDevices();
  if (device_count > 0) {
    rb_cvar_set(klass, devices_intern, get_devices(devices, device_count - 1));
  }
}

VALUE
find_all(VALUE klass) {
  VALUE devices = rb_cvar_get(klass, devices_intern);
  if (Qtrue == rb_funcall(devices, empty_intern, 0)) {
    populate_devices(klass);
  }
  return devices;
}
