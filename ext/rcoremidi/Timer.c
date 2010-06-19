#include "Base.h"

VALUE init_timer(VALUE self, VALUE tempo)
{
	rb_iv_set(self, "@tempo", tempo);
	return self;
}

VALUE start_timer(VALUE self)
{
	CFRunLoopRun();
	return Qtrue;
}