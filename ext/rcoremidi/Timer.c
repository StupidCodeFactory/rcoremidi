#include "Base.h"

VALUE init_timer(VALUE self, VALUE tempo)
{
	rb_iv_set(self, "@tempo", tempo);
	return self;
}

VALUE at(VALUE self, VALUE timestamp, VALUE block)
{
	if (rb_obj_is_kind_of(timestamp, rb_cTime) == Qtrue) {
		timestamp = time_to_f(timestamp);
		printf("%ld\n", timestamp);
	}

	return self;
}


VALUE start_timer(VALUE self)
{
	CFRunLoopRun();
	return Qtrue;
}