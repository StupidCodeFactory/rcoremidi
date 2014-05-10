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

        RCoremidiNode *clientNode     = (RCoremidiNode *)refCon;
        RCoreMidiTransport *transport = (RCoreMidiTransport *)clientNode->transport;

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

                                clientNode->callback->data = (void *)clientNode;


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

        MIDIEndpointRef *midi_source;
        TypedData_Get_Struct(source, MIDIEndpointRef, &midi_object_data_t, midi_source);

        CFPropertyListRef midi_properties;
        MIDIObjectGetProperties(*midi_source, &midi_properties, true);

        no_err(MIDIPortConnectSource( *clientNode->in, *midi_source, NULL), "Could not connect ouyput port tout source");

        rb_iv_set(self, "@source", source);
        rb_iv_set(self, "@is_connected", Qtrue);
        return Qtrue;
}

static void *midi_send_no_gvl(void *data)
{

        OSStatus error;
        midi_send_params_t *params = (midi_send_params_t *) data;

        MIDIPacketList  *packet_list = malloc(params->data_size);
        MIDIPacket      *packet      = MIDIPacketListInit(packet_list);
        Byte * debug = params->data;
        /* Byte d[3] = {0x90, 0x34, 0x65}; */
        /* printf ("debug - char: %s\n", (unsigned char *)debug); */
        /* params->data */
        /* params->data_size */


        packet = MIDIPacketListAdd(packet_list, 1024, packet, 0, params->data_size, params->data);
        if (packet == NULL)
                printf ("drop some midi packet\n");

        error = MIDISend(*params->out, *params->midi_destination, packet_list);

        if(error != noErr) {
                printf ("WARNING: Could not send midi packet\n");
        }

        return NULL;
}

VALUE send(VALUE self, VALUE destination, VALUE midi_stream)
{
        midi_send_params_t *midi_send_params = malloc(sizeof(midi_send_params_t));
        midi_send_params->data_size = NUM2ULONG(rb_funcall(midi_stream, length_intern, 0));
        long i;
        Byte *midi_data = malloc(midi_send_params->data_size);
        midi_send_params->data = midi_data;

        Byte *start = midi_send_params->data;
        printf ("sending:");
        for (i = 0; i < midi_send_params->data_size; ++i)
        {
                *midi_data = (Byte) NUM2UINT(rb_ary_entry(midi_stream, i));
                printf (" 0x%02X", (Byte)NUM2UINT(rb_ary_entry(midi_stream, i)));
                /* printf ("char: %s\n", (unsigned char *)midi_send_params->data); */
                midi_data++;
        }
        printf ("\n");
        RCoremidiNode *clientNode;
        TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, clientNode);

        midi_send_params->out = clientNode->out;

        MIDIEndpointRef *midi_destination;
        TypedData_Get_Struct(destination, MIDIObjectRef, &midi_object_data_t, midi_destination);

        midi_send_params->midi_destination = midi_destination;

        VALUE sent = (VALUE)rb_thread_call_without_gvl(midi_send_no_gvl, (void *) midi_send_params, NULL, NULL);

        return sent;
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
        created = MIDIInputPortCreate(*clientNode->client, CFSTR("input") , MidiReadProc, (void *)clientNode, clientNode->in);
        if (created != noErr) {
                rb_raise(rb_eRuntimeError, "Cound not create input port");
        }

        created = MIDIOutputPortCreate(*clientNode->client, CFSTR("output") , clientNode->out);
        if (created != noErr) {
                rb_raise(rb_eRuntimeError, "Cound not create output port");
        }

        rb_iv_set(self, "@name", name);
        clientNode->rb_client_obj = self;
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
