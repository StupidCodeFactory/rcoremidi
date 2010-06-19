#include "Base.h"

/*
* RCoreMidi::Client
* 
* 
*
*/

static void MidiReadProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon){

    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;	// remove const (!)
    unsigned int j;
    int i;

    for (j = 0; j < pktlist->numPackets; ++j) {
        for (i = 0; i < packet->length; ++i) {
         printf("count %d :\t%X\n",  packet->length, packet->data[i]);
    // 
    //      // rechannelize status bytes
    //                 //  if (packet->data[i] >= 0x80 && packet->data[i] < 0xF0)
    //                 //      packet->data[i] = (packet->data[i] & 0xF0) | gChannel;
    //                 // }
    // 
     // packet = MIDIPacketNext(packet);
        }
    }
    
    if (j > 100) {
        exit(0);
    }
}


VALUE client_init(int argc, VALUE *argv, VALUE self)
{
    VALUE name;
    VALUE in_port;
    VALUE out_port;
    VALUE client_ref;
	VALUE queue;
    rb_scan_args(argc, argv, "1", &name);

    
    // Ports:
    
    // Create midi input port
    in_port = rb_funcall(rb_cPort, rb_intern("new"), 0);
    rb_iv_set(self, "@input", in_port);
    
    // Create midi output port
    out_port = rb_funcall(rb_cPort, rb_intern("new"), 0);
    rb_iv_set(self, "@output", out_port);

    // Store each ports into there respective 
    // input and output port instance variables
    VALUE in_obj = rb_iv_get(rb_iv_get(self, "@input"), "@port_ref");
    VALUE out_obj = rb_iv_get(rb_iv_get(self, "@output"), "@port_ref");
    // Data_Get_Struct(obj, MIDIPortRef, DATA_PTR(obj));

    // ALLOC(MIDIClientRef)
    MIDIClientRef client;

    CFStringRef cName = CFStringCreateWithCString(NULL, RSTRING(name)->ptr, kCFStringEncodingUTF8);
                            // midinotifyProc
    OSStatus created;
    created = MIDIClientCreate(cName, NULL, NULL, &client);
    
    if (created != noErr) {
        rb_raise(rb_eRuntimeError, "Cound not create input port");
    }
    
    MIDIPortRef *in;
    MIDIPortRef *out;    

    Data_Get_Struct(in_obj,MIDIPortRef,in);

    Data_Get_Struct(out_obj,MIDIPortRef,out);

    created = MIDIInputPortCreate(client, CFSTR("input") , MidiReadProc, NULL, in);

    if (created != noErr) {
        rb_raise(rb_eRuntimeError, "Cound not create input port");
    } 


    created = MIDIOutputPortCreate(client, CFSTR("output") , out);
    
    if (created != noErr) {
        rb_raise(rb_eRuntimeError, "Cound not create output port");
    }


    MIDIClientRef *client_p = &client;
    client_ref = Data_Make_Struct(rb_cObject, MIDIClientRef, 0, free, client_p);

    rb_iv_set(self, "@client_ref", client_ref);
    rb_iv_set(self, "@name", name);
    rb_iv_set(self, "@source", Qnil);
	rb_iv_set(self, "@queue", Qnil);
	rb_iv_set(self, "@is_connected", Qfalse);

    CFRelease(cName);
		printf("proc TRIGGERED .....\n");
	if (rb_block_given_p()) {
		printf("proc TRIGGERED\n");
		rb_yield(self);

	}
		printf("proc TRIGGERED ..... ????\n");
    return self;
}

VALUE connect_to(VALUE self, VALUE source)
{

    VALUE in_obj = rb_iv_get(rb_iv_get(self, "@input"), "@port_ref");
    VALUE out_obj = rb_iv_get(rb_iv_get(self, "@output"), "@port_ref");
    VALUE endpoint = rb_iv_get(source,"@data");
    // This sits here for debuging purposes
    // I should make a macro to use this anywhere :*
/*
            switch (TYPE(in_obj)) {
                case T_FIXNUM:
                printf("%d\n", FIX2INT(in_obj));
                break;
                case T_STRING:
                printf("%s\n", StringValue(in_obj));
                break;
                case T_ARRAY:
                printf("array ?????\n");
                break;
                case T_NIL:
                printf("NIL\n");
                break;
                case T_OBJECT:
                printf("T_OBJECT\n");
                break;
                case T_CLASS:
                printf("T_CLASS\n");
                break;
                case T_DATA:
                printf("T_DATA\n");
                break;
                default:
                rb_raise(rb_eTypeError, "not valid value");
                break;
            }
        */

    // END OF DEBUG


	/*
	* may be i should malloc these guys
	* and then of cours free them
	*/
	
    MIDIPortRef *in;
    MIDIPortRef *out;
    MIDIEndpointRef *endpoint_ref;

    OSStatus connected;
    Data_Get_Struct(endpoint, MIDIEndpointRef, endpoint_ref);

    Data_Get_Struct(in_obj, MIDIPortRef, in);

    Data_Get_Struct(out_obj, MIDIPortRef, out);
    
    connected = MIDIPortConnectSource(*in, *endpoint_ref, NULL);
    if (connected != noErr) {
        rb_raise(rb_eRuntimeError, "Could not connect input port tout source");
    }
/*
    OSStatus connectedOut;
    printf("%p\n", *in);
    printf("%p\n", *out);
    connectedOut = MIDIPortConnectSource(*out, *endpoint_ref, NULL);
    if (connectedOut != noErr) {
        printf("%d\n", noErr);
        printf("%s\n", GetMacOSStatusErrorString(connectedOut));
        rb_raise(rb_eRuntimeError, "Could not connect ouyput port tout source");
    }
*/  	
	rb_iv_set(self, "@source", source);
	rb_iv_set(self, "@is_connected", Qtrue);
	
    return self;
}



void printProofTwo()
{
	printf("proof of concept TWO\n");
}