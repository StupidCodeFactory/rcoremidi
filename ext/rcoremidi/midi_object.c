#include "Base.h"

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
        MIDIDeviceRef *device_ref = malloc(sizeof(MIDIObjectRef));
        return TypedData_Make_Struct(klass, MIDIDeviceRef, &midi_object_data_t, device_ref);
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

static VALUE
create_entity_obj(MIDIEntityRef *midi_object)
{
        OSStatus error;
        CFPropertyListRef midi_properties;
        error = MIDIObjectGetProperties(*midi_object, &midi_properties, true);

        CFStringRef name;
        CFNumberRef uniqueID;
        SInt64 uid;

        set_name_from_properties(&midi_properties, &name);
        set_uid_from_properties(&midi_properties, &uniqueID, &uid);

        VALUE midi_entity = rb_funcall(rb_cEntity, new_intern, 0);

        rb_iv_set(midi_entity, "@name", rb_str_new2(CFStringGetCStringPtr(name, kCFStringEncodingUTF8)));
        rb_iv_set(midi_entity, "@uid", INT2FIX(uid));

        return midi_entity;
}

static VALUE
create_source_obj(MIDIEndpointRef *midi_object)
{

        OSStatus error;
        CFPropertyListRef midi_properties;
        error = MIDIObjectGetProperties(*midi_object, &midi_properties, true);

        CFNumberRef uniqueID;
        SInt64 uid;
        set_uid_from_properties(&midi_properties, &uniqueID, &uid);

        VALUE midi_source = rb_funcall(rb_cSource, new_intern, 0);
        rb_iv_set(midi_source, "@uid", INT2FIX(uid));

        return midi_source;
}

static VALUE
create_destination_obj(MIDIEndpointRef *midi_object)
{
        OSStatus error;
        CFPropertyListRef midi_properties;
        error = MIDIObjectGetProperties(*midi_object, &midi_properties, true);

        CFNumberRef uniqueID;
        SInt64 uid;
        set_uid_from_properties(&midi_properties, &uniqueID, &uid);

        VALUE midi_destination = rb_funcall(rb_cDestination, new_intern, 0);
        rb_iv_set(midi_destination, "@uid", INT2FIX(uid));

        return midi_destination;
}

static VALUE
create_device_obj(MIDIDeviceRef *midi_device)
{
        OSStatus error;
        CFPropertyListRef midi_properties;
        error = MIDIObjectGetProperties(*midi_device, &midi_properties, true);

        CFStringRef name;
        CFStringRef driver;
        CFStringRef manufacturer;
        CFNumberRef uniqueID;

        SInt64      uid;
        ItemCount   entities_count;
        ItemCount   i;

        set_name_from_properties(&midi_properties, &name);
        set_uid_from_properties(&midi_properties, &uniqueID, &uid);

        driver         = CFDictionaryGetValue(midi_properties, CFSTR("driver"));
        manufacturer   = CFDictionaryGetValue(midi_properties, CFSTR("manufacturer"));

        VALUE midi_object = rb_funcall(rb_cDevice, new_intern, 0);
        VALUE rb_entities = rb_ary_new();

        rb_iv_set(midi_object, "@name", rb_str_new2(CFStringGetCStringPtr(name, kCFStringEncodingUTF8)));
        rb_iv_set(midi_object, "@driver", rb_str_new2(CFStringGetCStringPtr(driver, kCFStringEncodingUTF8)));
        rb_iv_set(midi_object, "@manufacturer", rb_str_new2(CFStringGetCStringPtr(manufacturer, kCFStringEncodingUTF8)));
        rb_iv_set(midi_object, "@uid", INT2FIX(uid));
        rb_iv_set(midi_object, "@entities", rb_entities);

        entities_count = MIDIDeviceGetNumberOfEntities(*midi_device);
        for (i = 0; i < entities_count; ++i)
        {
                MIDIEntityRef midi_entity = MIDIDeviceGetEntity(*midi_device, i);
                MIDIObjectGetProperties(midi_entity, &midi_properties, true);
                rb_ary_push(rb_entities, create_entity_obj(&midi_entity));
        }
        return midi_object;
}

VALUE
find_by_unique_id(VALUE klass, VALUE uid)
{

        /* TODO: check for NULL pointer */
        MIDIObjectRef  *outObject     = malloc(sizeof(MIDIObjectRef));
        MIDIObjectType *outObjectType = malloc(sizeof(MIDIObjectType));

        MIDIObjectFindByUniqueID((MIDIUniqueID)FIX2INT(uid), outObject, outObjectType);


        /* CFShow(midi_properties); */

        switch(*outObjectType) {
        case kMIDIObjectType_Device:
                return create_device_obj((MIDIDeviceRef *)outObject);
        case kMIDIObjectType_Entity:
                return create_entity_obj((MIDIEntityRef *)outObject);
        case  kMIDIObjectType_Source:
                return create_source_obj((MIDIEndpointRef *)outObject);
        case kMIDIObjectType_Destination:
                return create_destination_obj((MIDIEndpointRef *)outObject);
        default:
                /* raise an exception of unhandled object type  */
                printf ("unkonwn type\n");

        }
        return Qnil;
}
