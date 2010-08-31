#ifndef CLIENT_H
#define CLIENT_H

VALUE client_init(int argc, VALUE *argv, VALUE self);
VALUE connect_to(VALUE self, VALUE source);
VALUE dispose_client(VALUE self);
VALUE cClientAlloc(VALUE klass);
VALUE start(VALUE self);
VALUE stop(VALUE stop);
VALUE client_alloc();

typedef struct RCoreMidiTransport
{
	UInt64 start_timestamp  = 0;
	unsigned int tempo      = 0;
	unsigned int tick_count = 0;
	unsigned int bar        = 0;
	unsigned int quarter    = 0;
	unsigned int eigth 	    = 0;
	unsigned int sixteinth  = 0;
} RCoreMidiTransport;

typedef struct RCoremidiNode
{
    MIDIClientRef *client;
    char *name;
    MIDIPortRef *in;
    MIDIPortRef *out;
	RCoreMidiTransport transport;
} RCoremidiNode;


#endif




