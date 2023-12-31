#ifndef CLIENT_H
#define CLIENT_H

VALUE client_init(VALUE self, VALUE name);
VALUE connect_to(VALUE self, VALUE source);
VALUE dispose_client(VALUE self);
VALUE cClientAlloc(VALUE klass);
VALUE stop(VALUE stop);
VALUE client_alloc(VALUE klass);
VALUE send_packets(VALUE self, VALUE destination, VALUE packets);
VALUE start_client(VALUE self);

static Byte *convert_to_bytes(Byte *bytes, VALUE midi_bytes);

typedef struct RCoreMidiTransport {
  MIDITimeStamp current_timestamp;
  UInt64 delta;
  unsigned short state;
  float mpt;
  UInt64 tick_count;
  unsigned int bar;
  unsigned int quarter;
  unsigned int eigth;
  unsigned int sixteinth;
} RCoreMidiTransport;

#endif
