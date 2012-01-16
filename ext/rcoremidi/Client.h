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
	UInt64 start_timestamp;
	unsigned short state; 
	unsigned int tempo;
	unsigned int tick_count;
	unsigned int bar;
	unsigned int quarter;
	unsigned int eigth;
	unsigned int sixteinth;
} RCoreMidiTransport;

typedef struct RCoremidiNode
{
    MIDIClientRef *client;
    char *name;
    MIDIPortRef *in;
    MIDIPortRef *out;
} RCoremidiNode;


#endif




