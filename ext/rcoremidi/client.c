#include "rcoremidi.h"
#include <CoreFoundation/CoreFoundation.h>
#include <MacTypes.h>
#include <limits.h>
#include <mach_debug/ipc_info.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
static ByteCount max_packet_list_size = 65536;

static void midi_node_free(void *ptr) {
  RCoremidiNode *tmp = ptr;
  if (tmp) {
    // May be (also) use MIDICLientDispose() from OSX API?
    // Anyway is this usefull or should i just need to
    // free the struct RCoremidiNode. Any just to make sure i free all
    free(tmp->client);
    free(tmp->transport);
    free(tmp->name);
    free(tmp->in);
    free(tmp->out);
    free(tmp);
  }
}

static size_t midi_node_memsize(const void *ptr) {
  return ptr ? sizeof(RCoremidiNode) : 0;
}

const rb_data_type_t midi_node_data_t = {
    "midi_node", {0, midi_node_free, midi_node_memsize}};

static RCoreMidiTransport *reset_transport(RCoreMidiTransport *transport) {
  transport->tick_count = 0;
  transport->bar = 1;
  transport->quarter = 0;
  transport->eigth = 0;
  transport->sixteinth = 0;
  return transport;
}

static RCoreMidiTransport *transport_alloc() {
  RCoreMidiTransport *transport = malloc(sizeof(RCoreMidiTransport));
  return reset_transport(transport);
}

static CFDataRef MIDIClockSynchronisation(CFMessagePortRef local, SInt32 msgid,
                                          CFDataRef data, void *info) {

  RCoreMidiTransport *transport = (RCoreMidiTransport *)CFDataGetBytePtr(data);
  CFMessagePortContext context;
  CFMessagePortGetContext(local, &context);
  RCoremidiNode *clientNode = (RCoremidiNode *)context.info;

  if (transport->tick_count == 0) {
    rb_funcall(clientNode->rb_client_obj, rb_intern("on_start"), 0);
  } else {
    rb_funcall(clientNode->rb_client_obj, rb_intern("on_tick"), 1,
               UINT2NUM(clientNode->transport->tick_count));
  }

  CFDataRef newData = CFDataCreate(NULL, 0, 0);
  return newData;
}

VALUE client_alloc(VALUE klass) {

  RCoremidiNode *clientNode;
  VALUE obj = TypedData_Make_Struct(klass, RCoremidiNode, &midi_node_data_t,
                                    clientNode);
  clientNode->client = malloc(sizeof(MIDIClientRef));
  clientNode->name = (char *)malloc(strlen("name"));
  clientNode->transport = transport_alloc();
  clientNode->in = malloc(sizeof(MIDIPortRef));
  clientNode->out = malloc(sizeof(MIDIPortRef));
  clientNode->out = malloc(sizeof(MIDIPortRef));
  return obj;
}

static void notifyProc(const MIDINotification *notification, void *refCon) {
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

static void MidiReadProc(const MIDIPacketList *pktlist, void *refCon,
                         void *connRefCon) {

  CFStringRef midiClientPortName = CFSTR("com.rcoremidi.MainThread");
  CFMessagePortRef mainThreadPort =
      CFMessagePortCreateRemote(NULL, midiClientPortName);
  CFRelease(midiClientPortName);

  CFStringRef MIDIReadProcPortName = CFSTR("com.rcoremidi.CallbackThread");
  CFMessagePortContext context = {0, NULL, NULL, NULL, NULL};
  Boolean shouldFreeInfo;
  CFMessagePortRef MIDIReadProcPort = CFMessagePortCreateLocal(
      NULL, MIDIReadProcPortName, NULL, &context, &shouldFreeInfo);

  CFRunLoopSourceRef MIDIReadProcRunLoopSource =
      CFMessagePortCreateRunLoopSource(NULL, MIDIReadProcPort, 0);
  if (MIDIReadProcRunLoopSource != NULL) {
    CFRunLoopAddSource(CFRunLoopGetCurrent(), MIDIReadProcRunLoopSource,
                       kCFRunLoopDefaultMode);
    CFRelease(MIDIReadProcPort);
    CFRelease(MIDIReadProcRunLoopSource);
  } else {
    fprintf(stderr, "Could not create RunLoopSource for MIDIReadProc\n");
  }
  /* printf("MIDIPacketList.numPackets: %d\n", pktlist->numPackets); */
  MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
  unsigned int j;
  int i;

  RCoremidiNode *clientNode = (RCoremidiNode *)refCon;
  RCoreMidiTransport *transport = (RCoreMidiTransport *)clientNode->transport;
  unsigned char *bytes;
  CFDataRef outData;
  SInt32 response;
  for (j = 0; j < pktlist->numPackets; ++j) {
    /* printf("packet.length: %d MIDIPacketList.numPackets\n", */
    /*        pktlist->numPackets); */

    for (i = 0; i < packet->length; ++i) {
      /* printf("packet->timestamp: %lld = packet->length: %d - MIDI PACKET " */
      /*        "DATAL: %#04x - %d\n", */
      /*        packet->timeStamp, packet->length, packet->data[i], */
      /*        packet->data[i]); */
      switch (packet->data[i]) {
      case kMIDIStart:
        printf("START: %d\n", transport->tick_count);
        bytes = malloc(sizeof(RCoreMidiTransport));
        memcpy(bytes, (const unsigned char *)transport,
               sizeof(RCoreMidiTransport));
        outData = CFDataCreate(NULL, bytes, sizeof(RCoreMidiTransport));

        response = CFMessagePortSendRequest(
            mainThreadPort, transport->tick_count, outData, 0, 0, NULL, NULL);
        response = CFMessagePortSendRequest(
            mainThreadPort, transport->tick_count, outData, 0, 0, NULL, NULL);
        switch (response) {
        case kCFMessagePortSendTimeout:
          fprintf(stderr, "Error sending MIDI Beat Clock: timeout\n");
          break;
        case kCFMessagePortIsInvalid:
          fprintf(stderr, "Error sending MIDI Beat Clock: Invalid MachPort\n");
          break;
        case kCFMessagePortTransportError:
          fprintf(stderr, "Error sending MIDI Beat Clock: Transport Error\n");
          break;
        case kCFMessagePortBecameInvalidError:
          fprintf(stderr,
                  "Error sending MIDI Beat Clock: MachPort became invalid\n");
          break;
        }
        transport->current_timestamp = mach_absolute_time();

        break;
      case kMIDIStop:
        printf("Stoping Client...\n");
        break;
      case kMIDITick:
        transport->tick_count++;
        bytes = malloc(sizeof(RCoreMidiTransport));
        memcpy(bytes, (const unsigned char *)transport,
               sizeof(RCoreMidiTransport));
        outData = CFDataCreate(NULL, bytes, sizeof(RCoreMidiTransport));

        response = CFMessagePortSendRequest(
            mainThreadPort, transport->tick_count, outData, 0, 0, NULL, NULL);
        switch (response) {
        case kCFMessagePortSendTimeout:
          fprintf(stderr, "Error sending MIDI Beat Clock: timeout\n");
          break;
        case kCFMessagePortIsInvalid:
          fprintf(stderr, "Error sending MIDI Beat Clock: Invalid MachPort\n");
          break;
        case kCFMessagePortTransportError:
          fprintf(stderr, "Error sending MIDI Beat Clock: Transport Error\n");
          break;
        case kCFMessagePortBecameInvalidError:
          fprintf(stderr,
                  "Error sending MIDI Beat Clock: MachPort became invalid\n");
          break;
        }

        /* printf("%d\n", transport->tick_count); */
        if ((transport->tick_count % 96) == 0) {
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

        break;
      case kMIDISongPositionPointer:
        reset_transport(transport);
        break;
      }

      // rechannelize status bytes
      /* if (packet->data[i] >= 0x80 && packet->data[i] < 0xF0) { */
      /*   packet->data[i] = (packet->data[i] & 0xF0) | 0; */
      /* } */

      /* printf("status byte %X data byte 1: %X data byte 2: %X\n",
       * packet->data[i], packet->data[i+1], packet->data[i+2]); */
    }

    packet = MIDIPacketNext(packet);
  }
}

VALUE connect_to(VALUE self, VALUE source) {
  RCoremidiNode *clientNode;
  TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, clientNode);

  MIDIEndpointRef *midi_source;
  TypedData_Get_Struct(source, MIDIEndpointRef, &midi_object_data_t,
                       midi_source);

  CFPropertyListRef midi_properties;
  MIDIObjectGetProperties(*midi_source, &midi_properties, true);

  no_err(MIDIPortConnectSource(*clientNode->in, *midi_source, NULL),
         "Could not connect ouyput port tout source");

  rb_iv_set(self, "@source", source);
  return Qtrue;
}

static void *midi_send_no_gvl(void *data) {

  OSStatus error;
  midi_send_params_t *params = (midi_send_params_t *)data;

  MIDIPacketList *packet_list = malloc(params->data_size);
  MIDIPacket *packet = MIDIPacketListInit(packet_list);

  packet = MIDIPacketListAdd(packet_list, 1024, packet, 0, params->data_size,
                             params->data);
  if (packet == NULL)
    printf("drop some midi packet\n");

  error = MIDISend(*params->out, *params->midi_destination, packet_list);

  if (error != noErr) {
    printf("WARNING: Could not send midi packet\n");
  }

  return NULL;
}

VALUE x_send(VALUE self, VALUE destination, VALUE midi_stream) {

  midi_send_params_t *midi_send_params = malloc(sizeof(midi_send_params_t));
  midi_send_params->data_size =
      NUM2ULONG(rb_funcall(midi_stream, length_intern, 0));
  printf("BYTES COUNT: %ld\n", midi_send_params->data_size);
  unsigned long i;
  Byte *midi_data = malloc(midi_send_params->data_size);
  midi_send_params->data = midi_data;

  for (i = 0; i < midi_send_params->data_size; ++i) {
    *midi_data = (Byte)NUM2CHR(rb_ary_entry(midi_stream, i));
    printf(" 0x%02X", (Byte)NUM2CHR(rb_ary_entry(midi_stream, i)));
    midi_data++;
  }

  RCoremidiNode *clientNode;
  TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, clientNode);

  midi_send_params->out = clientNode->out;

  MIDIEndpointRef *midi_destination;
  TypedData_Get_Struct(destination, MIDIObjectRef, &midi_object_data_t,
                       midi_destination);

  midi_send_params->midi_destination = midi_destination;

  VALUE sent = (VALUE)rb_thread_call_without_gvl(
      midi_send_no_gvl, (void *)midi_send_params, NULL, NULL);

  return Qtrue;
}

static Byte *convert_to_bytes(Byte *tail, VALUE midi_bytes) {
  if (rb_funcall(midi_bytes, empty_intern, 0) == Qtrue) {
    return tail;
  }

  *tail = NUM2UINT(rb_ary_shift(midi_bytes));
  tail++;

  return convert_to_bytes(tail, midi_bytes);
}

VALUE send_packets(VALUE self, VALUE destination, VALUE packets) {
  int notes_count, i;

  VALUE note, midi_payload;

  ByteCount midi_payload_size;
  Byte *bytes, *tail;

  RCoremidiNode *clientNode;
  MIDIEndpointRef *midi_destination;
  MIDIPacketList *packet_list;
  MIDIPacket *midi_packet;
  MIDITimeStamp timestamp;

  notes_count = NUM2INT(rb_funcall(packets, length_intern, 0));

  packet_list = malloc(65536);
  midi_packet = MIDIPacketListInit(packet_list);
  UInt64 t = mach_absolute_time();
  for (i = 0; i < notes_count; ++i) {

    note = rb_ary_entry(packets, i);
    midi_payload = rb_funcall(note, on_intern, 0);
    midi_payload_size = NUM2ULONG(rb_funcall(midi_payload, length_intern, 0));

    bytes = tail = malloc(midi_payload_size);
    convert_to_bytes(tail, midi_payload);
    timestamp = t + AudioConvertNanosToHostTime(
                        NUM2ULL(rb_funcall(note, on_timestamp_intern, 0)));
    midi_packet =
        MIDIPacketListAdd(packet_list, max_packet_list_size, midi_packet,
                          timestamp, midi_payload_size, bytes);

    if (midi_packet == NULL) {
      rb_raise(rb_eRuntimeError, "no more space in the packet list");
    }

    midi_payload = rb_funcall(note, off_intern, 0);
    midi_payload_size = NUM2ULONG(rb_funcall(midi_payload, length_intern, 0));

    tail = bytes;
    convert_to_bytes(tail, midi_payload);
    timestamp = t + NUM2ULL(rb_funcall(note, off_timestamp_intern, 0));
    midi_packet =
        MIDIPacketListAdd(packet_list, max_packet_list_size, midi_packet,
                          timestamp, midi_payload_size, bytes);

    if (midi_packet == NULL) {
      rb_raise(rb_eRuntimeError, "no more space in the packet list");
    }
  }

  TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, clientNode);
  TypedData_Get_Struct(destination, MIDIObjectRef, &midi_object_data_t,
                       midi_destination);

  MIDISend(*clientNode->out, *midi_destination, packet_list);
  return Qnil;
}

VALUE client_init(VALUE self, VALUE name) {

  RCoremidiNode *clientNode;
  TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, clientNode);

  CFStringRef midiClientPortName;
  CFMessagePortRef midiClientPort;
  CFRunLoopSourceRef midiClientSource;
  CFMessagePortContext context = {0, clientNode, NULL, NULL, NULL};
  Boolean shouldFreeInfo;

  midiClientPortName = CFSTR("com.rcoremidi.MainThread");
  midiClientPort = CFMessagePortCreateLocal(NULL, midiClientPortName,
                                            &MIDIClockSynchronisation, &context,
                                            &shouldFreeInfo);
  if (midiClientPort != NULL) {
    midiClientSource =
        CFMessagePortCreateRunLoopSource(NULL, midiClientPort, 0);
    if (midiClientSource != NULL) {
      CFRunLoopAddSource(CFRunLoopGetCurrent(), midiClientSource,
                         kCFRunLoopDefaultMode);

      CFRunLoopStop(CFRunLoopGetCurrent());
      CFRelease(midiClientSource);
    } else {
      fprintf(stderr, "No midiClientRunLoopSource was created\n");
    }

    CFRelease(midiClientPort);
  } else {
    fprintf(stderr, "No midiClientMachPort was created\n");
  }

  CFStringRef cName =
      CFStringCreateWithCString(NULL, RSTRING_PTR(name), kCFStringEncodingUTF8);

  OSStatus created; // Notify refcon!!! I should make
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
  created =
      MIDIInputPortCreate(*clientNode->client, CFSTR("input"), MidiReadProc,
                          (void *)clientNode, clientNode->in);
  if (created != noErr) {
    rb_raise(rb_eRuntimeError, "Cound not create input port");
  }

  created = MIDIOutputPortCreate(*clientNode->client, CFSTR("output"),
                                 clientNode->out);
  if (created != noErr) {
    rb_raise(rb_eRuntimeError, "Cound not create output port");
  }

  rb_iv_set(self, "@name", name);

  clientNode->rb_client_obj = self;
  return self;
}

static void handle_sigint(int sig) { CFRunLoopStop(CFRunLoopGetCurrent()); }

VALUE start_client(VALUE self) {
  signal(SIGINT, handle_sigint);
  CFRunLoopRun();
  printf("stopping client run loop\n");
  return Qnil;
}

VALUE dispose_client(VALUE self) {
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
  error = MIDIClientDispose((MIDIClientRef)*clientNode->client);
  if (error != noErr) {
    rb_raise(rb_eRuntimeError, "Could not dispose midi client");
  }
  return self;
}
