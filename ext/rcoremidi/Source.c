#include "Base.h"

static void midi_endpoint_free(void *ptr)
{
    printf("FREEING midi endpoint \n");
    MIDIEndpointRef *tmp = ptr;
    if(tmp) {
        // May be (also) use MIDICLientDispose() from OSX API?
        // Anyway is this usefull or should i just need to 
        // free the struct RCoremidiNode. Any just to make sure i free all
        // (dawm it, i always wanted to be a saviour, i guess this i my hour of glory)
        free(tmp);
    }
}

static size_t midi_endpoint_memsize(const void *ptr)
{
    printf("MIDI NOTE MEMSIZE\n");
    return ptr ? sizeof(MIDIEndpointRef) : 0;
}


static const rb_data_type_t midi_endpoint_data_t = {
    "midi_enpoint",
    0, midi_endpoint_free, midi_endpoint_memsize
};

VALUE source_alloc(VALUE klass)
{
    MIDIEndpointRef *endpoint;
    VALUE obj = TypedData_Make_Struct(klass, MIDIEndpointRef, &midi_endpoint_data_t, endpoint);
    return obj;
}


VALUE source_init(VALUE self, VALUE name, VALUE endpoint)
{
    rb_iv_set(self, "@name", name);
    rb_iv_set(self, "@data", endpoint);
    return self;
}
