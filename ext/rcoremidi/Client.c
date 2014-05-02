#include "rcoremidi.h"

static void midi_node_free(void *ptr)
{
        RCoremidiNode *tmp = ptr;
        if(tmp) {
                // May be (also) use MIDICLientDispose() from OSX API?
                // Anyway is this usefull or should i just need to
                // free the struct RCoremidiNode. Any just to make sure i free all
                free(tmp->client);
                free(tmp->transport);
                free(tmp->name);
                free(tmp->in);
                free(tmp->out);
                pthread_mutex_destroy(&tmp->callback->mutex);
                pthread_cond_destroy(&tmp->callback->cond);
                free(tmp->callback);
                free(tmp);
        }
}

static size_t midi_node_memsize(const void *ptr)
{
        return ptr ? sizeof(RCoremidiNode) : 0;
}


const rb_data_type_t midi_node_data_t = {
        "midi_node",
        0, midi_node_free, midi_node_memsize
};

RCoremidiNode * client_get_data(VALUE self) {
        RCoremidiNode * clientNode;
        TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, clientNode);
        return clientNode;
}

static RCoreMidiTransport * reset_transport(RCoreMidiTransport * transport) {
        transport->tick_count = 0;
        transport->bar        = 0;
        transport->quarter    = 0;
        transport->eigth      = 0;
        transport->sixteinth  = 0;
        return transport;
}

static RCoreMidiTransport * transport_alloc()
{
        RCoreMidiTransport * transport = malloc(sizeof(RCoreMidiTransport));
        return reset_transport(transport);
}

VALUE client_alloc(VALUE klass)
{
        RCoremidiNode *clientNode;
        VALUE obj = TypedData_Make_Struct(klass, RCoremidiNode, &midi_node_data_t, clientNode);
        clientNode->client        = malloc(sizeof(MIDIClientRef));
        clientNode->name          = (char *)malloc(strlen("name"));
        clientNode->transport     = transport_alloc();
        clientNode->in            = malloc(sizeof(MIDIPortRef));
        clientNode->out           = malloc(sizeof(MIDIPortRef));
        clientNode->out           = malloc(sizeof(MIDIPortRef));
        clientNode->callback      = malloc(sizeof(callback_t));
        pthread_mutex_init(&clientNode->callback->mutex, NULL);
        pthread_cond_init(&clientNode->callback->cond, NULL);
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


VALUE midi_in_callback(void *data)
{
        callback_t *callback = (callback_t *)data;
        return Qtrue;
}

static void MidiReadProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon) {
        MIDIPacket *packet = (MIDIPacket *)pktlist->packet; // remove const (!)
        unsigned int j;
        int i;

        VALUE client = (VALUE)connRefCon;
        RCoremidiNode *clientNode;
        TypedData_Get_Struct((VALUE)connRefCon, RCoremidiNode, &midi_node_data_t, clientNode);

        RCoreMidiTransport *transport = clientNode->transport;

        for (j = 0; j < pktlist->numPackets; ++j) {

                for (i = 0; i < packet->length; ++i) {

                        switch(packet->data[i]) {
                        case kMIDIStart:
                                transport->start_timestamp = AudioGetCurrentHostTime();

                                printf("Starting at %llu\n, host clock Fz: %lf, minimu delta %d\n",
                                       AudioGetCurrentHostTime(),
                                       AudioGetHostClockFrequency(),
                                       AudioGetHostClockMinimumTimeDelta());
                                break;
                        case kMIDIStop:
                                printf("Stoping Client...\n");
                                break;
                        case kMIDITick:
                                transport->tick_count++;

                                if((transport->tick_count % 64) == 0)
                                {
                                        transport->bar++;
                                }
                                // quarter
                                if ((transport->tick_count % 24) == 0) {
                                        transport->quarter++;
                                }
                                // eigth
                                if ((transport->tick_count % 12) == 0) {
                                        transport->eigth++;
                                }
                                // sixteinth
                                if ((transport->tick_count % 8) == 0) {
                                        transport->sixteinth++;
                                }

                                clientNode->callback->data = (void *)client;


                                pthread_mutex_lock(&g_callback_mutex);
                                g_callback_queue_push(clientNode->callback);
                                pthread_mutex_unlock(&g_callback_mutex);

                                pthread_cond_signal(&g_callback_cond);

                                break;
                        case kMIDISongPositionPointer:
                                reset_transport(transport);
                                break;
                        }


                        // rechannelize status bytes
                        if (packet->data[i] >= 0x80 && packet->data[i] < 0xF0) {
                                packet->data[i] = (packet->data[i] & 0xF0) | 0;
                        }

                        /* printf("status byte %X data byte 1: %X data byte 2: %X\n",
                           packet->data[i], packet->data[i+1], packet->data[i+2]); */

                }

                packet = MIDIPacketNext(packet);
        }

}

VALUE connect_to(VALUE self, VALUE source)
{
        RCoremidiNode *clientNode;
        TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, clientNode);

        MIDIEndpointRef *endpt;
        TypedData_Get_Struct(source, MIDIEndpointRef, &midi_object_data_t, endpt);

        CFPropertyListRef midi_properties;
        MIDIObjectGetProperties(*clientNode->in, &midi_properties, true);
        CFShow(midi_properties);

        no_err(MIDIPortConnectSource( *clientNode->in, *endpt, NULL), "Could not connect ouyput port tout source");

        rb_iv_set(self, "@source", source);
        rb_iv_set(self, "@is_connected", Qtrue);
        return Qtrue;
}


VALUE send(VALUE self, VALUE destination, VALUE midi_stream)
{
        VALUE stream_length = rb_funcall(midi_stream, length_intern, 0);
        VALUE format        = rb_str_times(rb_str_new2("C"), stream_length);
        VALUE bytes         = rb_funcall(midi_stream, pack_intern, format);

        RCoremidiNode *clientNode;
        TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, clientNode);

        MIDIPortRef *out = clientNode->out;

        MIDIEndpointRef *midi_destination;
        TypedData_Get_Struct(destination, MIDIObjectRef, &midi_object_data_t, midi_destination);
        printf ("THERE\n");
        MIDIPacketList  *packet_list = malloc(256);
        MIDIPacket      *packet      = MIDIPacketListInit(packet_list);
        packet = MIDIPacketListAdd(packet_list, 256, packet, 0, stream_length, (unsigned char*)StringValuePtr(bytes));
        return Qnil;
}

VALUE client_init(int argc, VALUE *argv, VALUE self)
{
        VALUE name;
        VALUE client_ref;
        rb_scan_args(argc, argv, "1", &name);


        RCoremidiNode *clientNode;
        TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, clientNode);

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
                rb_raise(rb_eRuntimeError, "Could dispose midi client");
        }
        return self;
}
