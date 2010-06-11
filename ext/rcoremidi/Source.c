#include "Base.h"

VALUE source_init(VALUE self, VALUE name, VALUE endpoint)
{
    rb_iv_set(self, "@name", name);
    rb_iv_set(self, "@data", endpoint);
    return self;
}
