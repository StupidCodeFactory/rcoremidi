#include "Base.h"

VALUE rb_mRCOREMIDI;
VALUE rb_cConectionManager;
VALUE rb_cSource;
VALUE rb_cEndpoint;
VALUE rb_cClient;
VALUE rb_cPort;
VALUE rb_cMidiQueue;
VALUE rb_cMidiPacket;
VALUE rb_cTimer;

void
Init_rcoremidi()
{
    rb_mRCOREMIDI = rb_define_module("RCoreMidi");
    
    /*
    * RCoreMidi::Endpoint
    */
    rb_cEndpoint =  rb_define_class_under(rb_mRCOREMIDI, "Endpoint", rb_cObject);

    /*
    * RCoreMidi::Port
    */
    rb_cPort =  rb_define_class_under(rb_mRCOREMIDI, "Port", rb_cObject);
    rb_define_method(rb_cPort, "initialize", port_init, 0);
    rb_define_attr(rb_cPort, "port_ref", 1, 0);
    /*
    * RCoreMidi::Client
    */
    rb_cClient =  rb_define_class_under(rb_mRCOREMIDI, "Client", rb_cObject);
    rb_define_method(rb_cClient, "initialize", client_init, -1);
    rb_define_method(rb_cClient, "connect_to", connect_to, 1);
    rb_define_attr(rb_cClient, "name", 1, 1);
    rb_define_attr(rb_cClient, "input", 1, 0);
    rb_define_attr(rb_cClient, "output", 1, 0);
    rb_define_attr(rb_cClient, "client_ref", 1, 0);
    rb_define_attr(rb_cClient, "source", 1, 0);
    rb_define_attr(rb_cClient, "queue", 1, 1);
    rb_define_attr(rb_cClient, "is_connected", 1, 1);
    /*
    * RCoreMidi::Source
    */
    rb_cSource = rb_define_class_under(rb_mRCOREMIDI, "Source", rb_cObject);
    rb_define_method(rb_cSource, "initialize", source_init, 2);
    rb_define_attr(rb_cSource, "data", 1, 0);

	rb_cMidiPacket = rb_define_class_under(rb_mRCOREMIDI, "MidiPacket", rb_cObject);

	/*
	* RCoreMidi::MidiQueue
	*/
	rb_cMidiQueue = rb_define_class_under(rb_mRCOREMIDI, "MidiQueue", rb_cObject);
	rb_define_method(rb_cMidiQueue, "initialize", init_midi_queue, 0);
    rb_define_attr(rb_cMidiQueue, "queue", 1, 1);

    /*
    * RCoreMidi::Source
    */
    rb_cConectionManager = rb_define_class_under(rb_mRCOREMIDI, "ConnectionManager", rb_cObject);
    rb_define_singleton_method(rb_cConectionManager, "devices", get_devices, 0);
	
    /*
    * RCoreMidi::Timer
    */

    rb_cTimer = rb_define_class_under(rb_mRCOREMIDI, "Timer", rb_cObject);
    rb_define_method(rb_cTimer, "initialize", init_timer, 1);
	rb_define_method(rb_cTimer, "start", start_timer, 0);
	rb_define_attr(rb_cTimer, "tempo", 1, 1);
	


  /* nothing here yet */
    printf("extension rcoremidi got loaded!\n"); /* TODO: remove me */
}
