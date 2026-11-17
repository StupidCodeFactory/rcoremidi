#ifndef CLIENT_H
#define CLIENT_H

VALUE client_alloc(VALUE klass);
VALUE client_init(VALUE self, VALUE name);
VALUE connect_to(VALUE self, VALUE source);
VALUE send_packets(int argc, VALUE *argv, VALUE self);
VALUE start_client(VALUE self);
VALUE stop_client(VALUE self);
VALUE client_running(VALUE self);
VALUE silence_client(VALUE self);
VALUE dropped_clock_events(VALUE self);
VALUE dispose_client(VALUE self);

#endif
