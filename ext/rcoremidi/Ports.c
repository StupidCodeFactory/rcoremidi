#include "Base.h"

VALUE port_init(VALUE self)
{
    VALUE port_ref;
    MIDIPortRef *in_port;
    port_ref = Data_Make_Struct(rb_cPort, MIDIPortRef, 0, free, in_port);

    rb_iv_set(self, "@port_ref", port_ref);
    return self;
}
