#include "Base.h"

VALUE 
init_midi_queue(VALUE self)
{
	VALUE queue = rb_hash_new();
	// @TODO set 96 keys with array to store MIDIPacket or MIDIPacketList
	rb_hash_aset(queue, key, )
	
	rb_iv_set(self, "@stack", queue);
	return self;
}