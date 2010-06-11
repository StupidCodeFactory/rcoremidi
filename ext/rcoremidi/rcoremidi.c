#include "Base.h"

VALUE rb_mRCOREMIDI;
VALUE rb_cConectionManager;
VALUE rb_cSource;
VALUE rb_cEndpoint;
VALUE rb_cClient;
VALUE rb_cPort;


void
Init_rcoremidi()
{
	printProofTwo();
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
    /*
    * RCoreMidi::Source
    */
    rb_cSource = rb_define_class_under(rb_mRCOREMIDI, "Source", rb_cObject);
    rb_define_method(rb_cSource, "initialize", source_init, 2);
    rb_define_attr(rb_cSource, "data", 1, 0);
    /*
    * RCoreMidi::Source
    */
        rb_cConectionManager = rb_define_class_under(rb_mRCOREMIDI, "ConectionManager", rb_cObject);
    rb_define_singleton_method(rb_cConectionManager, "devices", get_devices,0);

  /* nothing here yet */
    printf("extension rcoremidi got loaded!\n"); /* TODO: remove me */
}
