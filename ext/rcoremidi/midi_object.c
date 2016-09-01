#include "rcoremidi.h"
#include <AssertMacros.h>


static void
midi_object_free(void * ptr)
{
        free(ptr);
}

static size_t
midi_object_memsize(const void * ptr)
{



        return ptr ? sizeof(MIDIObjectRef) : 0;
}

const rb_data_type_t midi_object_data_t = {
        "midi_node",
        0,
        midi_object_free,
        midi_object_memsize
};

VALUE
midi_object_alloc(VALUE klass)
{
        MIDIObjectRef *device_ref = malloc(sizeof(MIDIObjectRef));
        return TypedData_Make_Struct(klass, MIDIObjectRef, &midi_object_data_t, device_ref);
}

static void
set_uid_from_properties(CFPropertyListRef *midi_properties, CFNumberRef *uniqueID, SInt64 *uid)
{
        *uniqueID = CFDictionaryGetValue(*midi_properties, CFSTR("uniqueID"));
        CFNumberGetValue(*uniqueID, CFNumberGetType(*uniqueID), uid);
}

static void
set_name_from_properties(CFPropertyListRef *midi_properties, CFStringRef *name)
{
        *name = CFDictionaryGetValue(*midi_properties, CFSTR("name"));
}

static void
assign_endpoint_properties(VALUE source, MIDIEndpointRef *midi_object)
{

        OSStatus error;
        CFPropertyListRef midi_properties;
        error = MIDIObjectGetProperties(*midi_object, &midi_properties, true);

        CFNumberRef uniqueID;
        SInt64 uid;
        set_uid_from_properties(&midi_properties, &uniqueID, &uid);

        rb_iv_set(source, "@uid", INT2FIX(uid));
}

MIDIObjectRef *get_midi_data(VALUE rb_midi_object)
{
        MIDIObjectRef *midi_object;
        TypedData_Get_Struct(rb_midi_object, MIDIObjectRef, &midi_object_data_t, midi_object);
        return midi_object;

}

static VALUE add_destination_to_entity(VALUE entity, VALUE endpoints, ItemCount count);
static VALUE add_source_to_entity(VALUE entity, VALUE endpoints, ItemCount count);
static VALUE add_entites_to_device(VALUE device, VALUE entities, ItemCount count);

static VALUE
create_entity()
{
        VALUE entity = rb_funcall(rb_cEntity, new_intern, 0);
        rb_iv_set(entity, "@endpoints", rb_ary_new());
        return entity;
}

static VALUE
create_device()
{
        VALUE device  = rb_funcall(rb_cDevice, new_intern, 0);
        rb_iv_set(device, "@entities", rb_ary_new());
        return device;
}

static VALUE
add_destination_to_entity(VALUE entity, VALUE endpoints, ItemCount count)
{
        VALUE destination = rb_funcall(rb_cDestination, new_intern, 0);

        MIDIEndpointRef *midi_destination = get_midi_data(destination);

        *midi_destination = MIDIEntityGetDestination(*get_midi_data(entity), count);

        assign_endpoint_properties(destination, midi_destination);

        rb_ary_push(endpoints, destination);

        if (count ==  0) {
                return endpoints;
        } else {
                count--;
                return add_destination_to_entity(entity, endpoints, count);
        }
}

static VALUE
add_source_to_entity(VALUE entity, VALUE endpoints, ItemCount count)
{

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

static void
assign_entity_properties(VALUE entity, MIDIEntityRef *midi_object)
{
        OSStatus error;
        CFPropertyListRef midi_properties;
        error = MIDIObjectGetProperties(*midi_object, &midi_properties, true);

        CFStringRef name = CFDictionaryGetValue(midi_properties, CFSTR("name"));
        CFNumberRef uniqueID;
        SInt64 uid;

        set_uid_from_properties(&midi_properties, &uniqueID, &uid);

        rb_iv_set(entity, "@name", rb_str_new2(CFStringGetCStringPtr(name, kCFStringEncodingUTF8)));
        rb_iv_set(entity, "@uid", INT2FIX(uid));
}

static VALUE add_entites_to_device(VALUE device, VALUE entities, ItemCount count)
{
        VALUE         entity       = create_entity();
        MIDIEntityRef *midi_entity = get_midi_data(entity);

        *midi_entity = MIDIDeviceGetEntity(*get_midi_data(device), count);

        assign_entity_properties(entity, midi_entity);

        ItemCount destination_or_source_count = MIDIEntityGetNumberOfSources(*midi_entity);
        if (destination_or_source_count > 0) {
                add_source_to_entity(entity, rb_iv_get(entity, "@endpoints"), destination_or_source_count - 1);
        }

        destination_or_source_count = MIDIEntityGetNumberOfDestinations(*midi_entity);
        if (destination_or_source_count > 0) {
                add_destination_to_entity(entity, rb_iv_get(entity, "@endpoints"), destination_or_source_count - 1);
        }

        rb_ary_push(rb_iv_get(device, "@entities"), entity);

        if (count == 0) {
                return entities;
        } else {
                count--;
                return add_entites_to_device(device, entities, count);
        }
}

static void
assign_device_properties(VALUE device, MIDIDeviceRef *midi_device)
{
        OSStatus error;
        CFPropertyListRef midi_properties;
        error = MIDIObjectGetProperties(*midi_device, &midi_properties, true);

        CFStringRef name;
        CFStringRef driver;
        CFStringRef manufacturer;
        CFNumberRef uniqueID;
        SInt64      uid;

        set_name_from_properties(&midi_properties, &name);
        set_uid_from_properties(&midi_properties, &uniqueID, &uid);

        driver         = CFDictionaryGetValue(midi_properties, CFSTR("driver"));
        manufacturer   = CFDictionaryGetValue(midi_properties, CFSTR("manufacturer"));

        rb_iv_set(device, "@name",         rb_str_new2(CFStringGetCStringPtr(name,         kCFStringEncodingUTF8)));
        rb_iv_set(device, "@driver",       rb_str_new2(CFStringGetCStringPtr(driver,       kCFStringEncodingUTF8)));
        rb_iv_set(device, "@manufacturer", rb_str_new2(CFStringGetCStringPtr(manufacturer, kCFStringEncodingUTF8)));
        rb_iv_set(device, "@uid",          INT2FIX(uid));
}


VALUE
find_by_unique_id(VALUE klass, VALUE uid)
{

        /* TODO: check for NULL pointer */
        MIDIObjectRef  midi_object;
        MIDIObjectType midi_object_type;



        OSStatus error;
        error = MIDIObjectFindByUniqueID((MIDIUniqueID)FIX2INT(uid), &midi_object, &midi_object_type);

        /* CFPropertyListRef midi_properties; */
        /* MIDIObjectGetProperties(midi_object, &midi_properties, true); */
        /* CFShow(midi_properties); */
        /* printf("OBJECT TYPE: %d\n", midi_object_type); */

        if (error == kMIDIObjectNotFound) {
                rb_raise(rb_eArgError, "MIDI Object not found %d\n", FIX2INT(uid));
        }


        if (midi_object_type == kMIDIObjectType_Device) {
                VALUE device = create_device();
                *get_midi_data(device) = midi_object;
                assign_device_properties(device, &midi_object);
                return device;
        } else if(midi_object_type == kMIDIObjectType_Entity) {
                VALUE entity = create_entity();
                *get_midi_data(entity) = midi_object;
                assign_entity_properties(entity, &midi_object);
                return entity;
        } else if(midi_object_type == kMIDIObjectType_Source) {
                VALUE source = rb_funcall(rb_cSource, new_intern, 0);
                *get_midi_data(source) = midi_object;
                assign_endpoint_properties(source, &midi_object);
                return source;
        } else if(midi_object_type == kMIDIObjectType_Destination) {
                VALUE destination = rb_funcall(rb_cDestination, new_intern, 0);
                *get_midi_data(destination) = midi_object;
                assign_endpoint_properties(destination, &midi_object);
                return destination;
        } else {
                rb_raise(rb_eArgError, "MIDI Object not found %d\n", FIX2INT(uid));
                return Qnil;
        }
}

static VALUE
get_devices(VALUE devices, ItemCount count)
{
        VALUE device               = create_device();
        MIDIDeviceRef *midi_device = get_midi_data(device);

        *midi_device = MIDIGetDevice(count);

        assign_device_properties(device, midi_device);

        rb_ary_push(devices, device);

        ItemCount entities_count = MIDIDeviceGetNumberOfEntities(*midi_device);

        if (entities_count > 0) {
                add_entites_to_device(device, rb_iv_get(device, "@entities"), entities_count - 1);
        }

        if (count == 0) {
                return devices;
        } else {
                count--;
                return get_devices(devices, count);
        }
}

static void
populate_devices(VALUE klass)
{
        VALUE devices = rb_cvar_get(klass, devices_intern);
        ItemCount device_count = MIDIGetNumberOfDevices();
        if (device_count > 0) {
                rb_cvar_set(klass, devices_intern, get_devices(devices, device_count - 1));
        }
}

VALUE
find_all(VALUE klass)
{
        VALUE mutex_lock = rb_cvar_get(klass, lock_intern);
        rb_mutex_lock(mutex_lock);
        VALUE devices = rb_cvar_get(klass, devices_intern);
        if (Qtrue == rb_funcall(devices, empty_intern, 0)) {
                populate_devices(klass);
        }
        rb_mutex_unlock(mutex_lock);
        return devices;
}
