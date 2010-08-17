#include "Base.h"

/*
* RCoreMidi::Client
* 
* 
*
*/

// static void send(VALUE self, VAlUE array)
// {
// 	
// }



void notifyProc(const MIDINotification *notification, void *refCon)
{
	switch (notification->messageID) {
		case kMIDIMsgSetupChanged:
			printf("MIDINotifyProc: SET UP HAS CHANGED\n");
			break;
		case kMIDIMsgPropertyChanged:
			printf("MIDINotifyProc: SET UP PROPERTY CHANGED\n");
			break;
		case kMIDIMsgIOError:
			printf("MIDINotifyProc: IO ERROR\n");
			break;
		case kMIDIMsgObjectAdded:
			printf("MIDINotifyProc: OBJECT ADDED\n");
			break;
		case kMIDIMsgObjectRemoved:
			printf("MIDINotifyProc: OBECT REMOVE\n");
			break;
		case kMIDIMsgSerialPortOwnerChanged:
			printf("MIDINotifyProc: SERAIL PORT OWNER CHAGED\n");
			break;
		case kMIDIMsgThruConnectionsChanged:
			printf("MIDINotifyProc: THRU CONNECTION CHANGED\n");
			break;
			
		default:
			printf("MIDINotifyProc: WHAT THE FUCK\n");
			break;
	}
}

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


    MIDIClientRef *client = ALLOC(MIDIClientRef);
    CFStringRef cName = CFStringCreateWithCString(NULL, RSTRING_PTR(name), kCFStringEncodingUTF8);

	// MIDINOTIFYPROC
    OSStatus created;
    created = MIDIClientCreate(cName, notifyProc, NULL, client);
    
    if (created != noErr) {
        rb_raise(rb_eRuntimeError, "Cound not create input port");
    }
    
    MIDIPortRef *in;
    MIDIPortRef *out;    

    Data_Get_Struct(in_obj,MIDIPortRef,in);

    Data_Get_Struct(out_obj,MIDIPortRef,out);

    created = MIDIInputPortCreate(*client, CFSTR("input") , MidiReadProc, NULL, in);
	
    if (created != noErr) {
        rb_raise(rb_eRuntimeError, "Cound not create input port");
    } 


    created = MIDIOutputPortCreate(*client, CFSTR("output") , out);
    
    if (created != noErr) {
        rb_raise(rb_eRuntimeError, "Cound not create output port");
    }

    client_ref = Data_Wrap_Struct(rb_cClient, NULL, free, client);

    rb_iv_set(self, "@client_ref", client_ref);
    rb_iv_set(self, "@name", name);
    rb_iv_set(self, "@source", Qnil);
	rb_iv_set(self, "@queue", Qnil);
	rb_iv_set(self, "@is_connected", Qfalse);

    return self;
}

VALUE start(VALUE self)
{
	printf("Staring th client in C\n");
	CFRunLoopRun();
	return self;
}

VALUE stop(VALUE self)
{
	CFRunLoopStop(CFRunLoopGetCurrent());
	return self;
}

VALUE connect_to(VALUE self, VALUE source)
{

    VALUE in_obj = rb_iv_get(rb_iv_get(self, "@input"), "@port_ref");
    VALUE out_obj = rb_iv_get(rb_iv_get(self, "@output"), "@port_ref");
    VALUE endpoint = rb_iv_get(source,"@data");

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

VALUE dispose_client(VALUE self)
{
	VALUE client_ref = rb_iv_get(self, "@client_ref");

	MIDIClientRef *client = ALLOC(MIDIClientRef);
	Data_Get_Struct(client_ref, MIDIClientRef, client);

    // // This sits here for debuging purposes
    // // I should make a macro to use this anywhere :*
    //         switch (TYPE(client_ref)) {
    //             case T_FIXNUM:
    //             printf("%d\n", FIX2INT(client_ref));
    //             break;
    //             case T_STRING:
    //             printf("%s\n", StringValue(client_ref));
    //             break;
    //             case T_ARRAY:
    //             printf("array ?????\n");
    //             break;
    //             case T_NIL:
    //             printf("NIL\n");
    //             break;
    //             case T_OBJECT:
    //             printf("T_OBJECT\n");
    //             break;
    //             case T_CLASS:
    //             printf("T_CLASS\n");
    //             break;
    //             case T_DATA:
    //             printf("T_DATA\n");
    //             break;
    //             default:
    //             rb_raise(rb_eTypeError, "not valid value");
    //             break;
    //         }
    // 
    // // END OF DEBUG
    // 
	
	OSStatus error;
	error = MIDIClientDispose((MIDIClientRef) *client);
	if (error != noErr) {
		printf("%s\n", GetMacOSStatusCommentString(error));
		rb_raise(rb_eRuntimeError, "Could dispose midi client");
	}
	rb_iv_set(self, "@client_ref", Qnil);
	return self;
}

