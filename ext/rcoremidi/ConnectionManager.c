#include "Base.h"



VALUE get_devices()
{
    VALUE arr = rb_ary_new();
    VALUE sources = rb_hash_new();

    int i;
    for(i = 0; i < (int) MIDIGetNumberOfSources(); ++i)
    {
        OSStatus status;
        VALUE rName = Qnil;

        VALUE source = rb_funcall(rb_cSource, rb_intern("new"), 1, rName);

        MIDIEndpointRef *endpoint;
        TypedData_Get_Struct(source, MIDIEndpointRef, &midi_endpoint_data_t, endpoint);
        *endpoint = MIDIGetSource((ItemCount)i);

        CFStringRef pname;
        status = MIDIObjectGetStringProperty(*endpoint, kMIDIPropertyDisplayName, &pname);
        if (status == noErr){
            char name[64];
            CFStringGetCString(pname, name, sizeof(name), kCFStringEncodingUTF8);
            VALUE rName = rb_external_str_new_cstr(name);
            rb_iv_set(source, "@name", rName);
            CFRelease(pname);
            rb_hash_aset(sources, INT2FIX(i+1), source);
        }
    }
    return sources;
}

