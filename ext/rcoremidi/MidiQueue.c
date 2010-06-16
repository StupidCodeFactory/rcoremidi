#include "Base.h"

VALUE 
init_midi_queue(VALUE self)
{
	VALUE queue = rb_hash_new();
	
	const char *timestamp_key = "timestamp";
	const char *midi_packet_key = "notes";	
	// @TODO set 96 keys with array to store MIDIPacket or MIDIPacketList
	int i;
	for(i = 0; i < 96; ++i)
	{
		VALUE tick_storage = rb_hash_new();
		VALUE rMidipacket;
		MIDIPacket *packet = ALLOC(MIDIPacket);
		rMidipacket = Data_Make_Struct(rb_cMidiPacket, MIDIPacket, 0, free, packet);
		rb_hash_aset(tick_storage, ID2SYM(rb_intern(timestamp_key)), Qnil);
		rb_hash_aset(tick_storage, ID2SYM(rb_intern(midi_packet_key)), rMidipacket);
		rb_hash_aset(queue, INT2FIX(i), tick_storage);
	}
	

	
	rb_iv_set(self, "@stack", queue);
	return self;
}