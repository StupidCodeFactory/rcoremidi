#include "Base.h"


void midi_endpoint_free(void *ptr)
{
    MIDIEndpointRef *tmp = ptr;
    if(tmp) {
        free(tmp);
    }
}

void midi_endpoint_mark(void *ptr)
{
    // printf("SHOULD i mark %p \n", ptr);
}

size_t midi_endpoint_memsize(const void *ptr)
{
    return ptr ? sizeof(MIDIEndpointRef) : 0;
}


const rb_data_type_t midi_endpoint_data_t = {
    "midi_enpoint",
    midi_endpoint_mark, midi_endpoint_free, midi_endpoint_memsize
};

/* VALUE source_alloc(VALUE klass) */
/* { */
/*     MIDIEndpointRef *endpoint = ALLOC(MIDIEndpointRef); */
/*     VALUE obj = TypedData_Wrap_Struct(klass, &midi_endpoint_data_t, endpoint); */
/*     return obj; */
/* } */


/* VALUE source_init(VALUE self, VALUE name) */
/* { */
/*     rb_iv_set(self, "@name", name); */
/*     return self; */
/* } */
