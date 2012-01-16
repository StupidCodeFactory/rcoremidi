#include "Base.h"

/*
* RCoreMidi::Client
* 
* 
*
*/

static RCoreMidiTransport transport;

static void midi_node_free(void *ptr)
{
    RCoremidiNode *tmp = ptr;
    if(tmp) {
        // May be (also) use MIDICLientDispose() from OSX API?
        // Anyway is this usefull or should i just need to 
        // free the struct RCoremidiNode. Any just to make sure i free all
        // (dawm it, i always wanted to be a saviour, i guess this i my hour of glory)
        free(tmp->client);
        free(tmp->name);
        free(tmp->in);
        free(tmp->out);
        free(tmp);
    }
}

static size_t midi_node_memsize(const void *ptr)
{
    return ptr ? sizeof(RCoremidiNode) : 0;
}


static const rb_data_type_t midi_node_data_t = {
    "midi_node",
    0, midi_node_free, midi_node_memsize
};

VALUE client_alloc(VALUE klass)
{
    RCoremidiNode *midiNode;
    VALUE obj = TypedData_Make_Struct(klass, RCoremidiNode, &midi_node_data_t, midiNode);
    midiNode->client = ALLOC(MIDIClientRef);
    midiNode->name   = NULL;
    midiNode->in     = ALLOC(MIDIPortRef);
    midiNode->out    = ALLOC(MIDIPortRef);
    return obj;
}

static void notifyProc(const MIDINotification *notification, void *refCon)
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
	
		/*
		* Check length:
		* if length == 1
		* 	=> parse packet => do whatever packet need
		* 
		* if length > 1
		*	send packet to function using agregated midi packet	
		*/
	
        for (i = 0; i < packet->length; ++i) {
        	printf("count %d :\t%X\n",  packet->length, packet->data[i]);

			switch(packet->data[i]) {
				case kMIDIStart:
					transport.start_timestamp = AudioGetCurrentHostTime();
					
					printf("Starting at %llu\n, host clock Fz: %lf, minimu delta %d\n", 
							AudioGetCurrentHostTime(), 
							AudioGetHostClockFrequency(), 
							AudioGetHostClockMinimumTimeDelta());
					break;
				case kMIDIStop:
					printf("Stoping Client...\n");
					break;
				case kMIDITick:
					transport.tick_count++;
					// bar
					if((transport.tick_count % 64) == 0)
					{
						printf("got a modulo 64  %d\n", transport.bar);
						transport.bar++;
					}
					// quarter
					if ((transport.tick_count % 24) == 0) {
						transport.quarter++;
						printf("QUARTER PASTED %d\n", transport.quarter);
					}
					// eigth
					if ((transport.tick_count % 12) == 0) {
						transport.eigth++;
					}
					// sixteinth
					if ((transport.tick_count % 8) == 0) {
						transport.sixteinth++;
					}
					break;
				case kMIDISongPositionPointer:
					break;
					// printf("status byte %X data byte 1: %X data byte 2: %X\n", packet->data[i], packet->data[i+1], packet->data[i+2]);
					
			}
          // rechannelize status bytes
          //  if (packet->data[i] >= 0x80 && packet->data[i] < 0xF0)
          //      packet->data[i] = (packet->data[i] & 0xF0) | gChannel;
          // }
    // 
     packet = MIDIPacketNext(packet);
        }
		printf("status byte %X data byte 1: %X data byte 2: %X\n\t tick count %d\n\t BAR: %d\n\t QARTER: %d\n\t EIGTH: %d\n\t SEIXTEENTH: %d\n\e[2J\e[f",
				packet->data[i], 
				packet->data[i+1], 
				packet->data[i+2],
				transport.tick_count,
				transport.bar,
				transport.quarter,
				transport.eigth,
				transport.sixteinth);

    	// printf("\ttick count: %d\n\tbar: %d\n", transport.tick_count, transport.bar); //\e[2J\e[f
    }

}



VALUE client_init(int argc, VALUE *argv, VALUE self)
{
    VALUE name;
    VALUE client_ref;
    rb_scan_args(argc, argv, "1", &name);


    RCoremidiNode *clientNode;
    TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, clientNode);

    clientNode->name   = (char *)malloc(strlen("name"));
    strncpy(clientNode->name, "name", strlen("name"));
    
    CFStringRef cName = CFStringCreateWithCString(NULL, RSTRING_PTR(name), kCFStringEncodingUTF8);

    OSStatus created;                 // Notify refcon!!! I should make 
									  // structure to identify midi client, if there are more than one
    created = MIDIClientCreate(cName, notifyProc, NULL, clientNode->client);
    if (created != noErr) {
        rb_raise(rb_eRuntimeError, "Cound not create input port");
    }
																					/*
																					* Then here i should 
																					* also make a structy idententifying 
																					* the input as there might be more than one 
																					*/
    created = MIDIInputPortCreate(*clientNode->client, CFSTR("input") , MidiReadProc, NULL, clientNode->in);
    if (created != noErr) {
        rb_raise(rb_eRuntimeError, "Cound not create input port");
    } 

    created = MIDIOutputPortCreate(*clientNode->client, CFSTR("output") , clientNode->out);
    if (created != noErr) {
        rb_raise(rb_eRuntimeError, "Cound not create output port");
    }
    
    rb_iv_set(self, "@name", name);
    rb_iv_set(self, "@queue", Qnil);

	// initialize transport
	transport.tempo 	 = 0;
	transport.tick_count = 0;
	transport.bar		 = 0;
	transport.quarter	 = 0;
	transport.eigth		 = 0;
	transport.sixteinth  = 0;
	
    return self;
}

VALUE connect_to(VALUE self, VALUE source)
{
    RCoremidiNode *clientNode;
    TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, clientNode);
    
    MIDIEndpointRef *endpt;
    TypedData_Get_Struct(source, MIDIEndpointRef, &midi_endpoint_data_t, endpt);

    OSStatus connectedOut;
    connectedOut = MIDIPortConnectSource(*clientNode->in, *endpt, NULL);
    if (connectedOut != noErr) {
        printf("%s\n", GetMacOSStatusCommentString(connectedOut));
        rb_raise(rb_eRuntimeError, "Could not connect ouyput port tout source");
    }
    rb_iv_set(self, "@source", source);
    rb_iv_set(self, "@is_connected", Qtrue);
    return self;
}

VALUE dispose_client(VALUE self)
{
    RCoremidiNode *clientNode;
    TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, clientNode);

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
	error = MIDIClientDispose((MIDIClientRef) *clientNode->client);
	if (error != noErr) {
		printf("%s\n", GetMacOSStatusCommentString(error));
		rb_raise(rb_eRuntimeError, "Could dispose midi client");
	}
	return self;
}



