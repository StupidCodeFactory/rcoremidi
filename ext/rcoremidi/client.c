#include "rcoremidi.h"
#include <dispatch/dispatch.h>
#include <mach/mach_time.h>
#include <stdatomic.h>
#include <stdlib.h>

enum ClockEventKind {
  kClockStart = 1,
  kClockTick,
  kClockStop,
  kClockContinue
};

enum MidiStatus {
  kMIDISongPositionPointer = 0xF2,
  kMIDITimingClock = 0xF8,
  kMIDIStart = 0xFA,
  kMIDIContinue = 0xFB,
  kMIDIStop = 0xFC,
  kMIDIControlChange = 0xB0,
  kMIDIAllSoundOff = 120,
  kMIDIAllNotesOff = 123
};

enum {
  kClockQueueCapacity = 1024,
  kMaxMIDIMessageLength = 256,
  kMIDIChannels = 16,
  kUniversalSystemMessage = 0x1,
  kUniversalMIDI1ChannelVoice = 0x2
};

static const ByteCount kEventListCapacity = 65536;
static const int64_t kTicksPerSixteenth = 6;
static const int64_t kClockWaitNanoseconds = 100 * NSEC_PER_MSEC;
static const int64_t kClockInputReleaseDelay = NSEC_PER_SEC;
static const long long kMaxScheduleAheadNanoseconds = 3600LL * NSEC_PER_SEC;

typedef struct ClockEvent {
  int kind;
  int64_t tick;
  MIDITimeStamp host_time;
} ClockEvent;

typedef struct ClockInput {
  ClockEvent events[kClockQueueCapacity];
  _Atomic uint64_t head;
  _Atomic uint64_t tail;
  _Atomic uint64_t dropped;
  atomic_bool listening;
  atomic_int receiving;
  int64_t tick;
  dispatch_semaphore_t signal;
} ClockInput;

typedef struct RCoremidiNode {
  MIDIPortRef in;
  MIDIPortRef out;
  bool ports_created;
  bool disposed;
  bool running;
  atomic_bool stop_requested;
  MIDIEndpointRef last_destination;
  ClockInput *clock;
} RCoremidiNode;

enum ReleaseOrder { kReleaseFirst = 0, kAttackAfterRelease = 1 };

typedef struct ScheduledMessage {
  MIDITimeStamp timestamp;
  enum ReleaseOrder release_order;
  long position;
  ByteCount word_count;
  UInt32 words[kMaxUniversalWordsPerMessage];
} ScheduledMessage;

static ClockInput *create_clock_input(void) {
  ClockInput *input = calloc(1, sizeof *input);
  if (!input) {
    return NULL;
  }
  input->signal = dispatch_semaphore_create(0);
  if (!input->signal) {
    free(input);
    return NULL;
  }
  return input;
}

static void schedule_clock_input_release(ClockInput *input);

static void free_clock_input_when_idle(void *ptr) {
  ClockInput *input = ptr;
  if (atomic_load(&input->receiving) > 0) {
    schedule_clock_input_release(input);
    return;
  }
  dispatch_release(input->signal);
  free(input);
}

static void schedule_clock_input_release(ClockInput *input) {
  dispatch_after_f(dispatch_time(DISPATCH_TIME_NOW, kClockInputReleaseDelay),
                   dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), input,
                   free_clock_input_when_idle);
}

static bool push_clock_event(ClockInput *input, ClockEvent event) {
  uint64_t tail = atomic_load_explicit(&input->tail, memory_order_relaxed);
  uint64_t head = atomic_load_explicit(&input->head, memory_order_acquire);
  if (tail - head == kClockQueueCapacity) {
    atomic_fetch_add_explicit(&input->dropped, 1, memory_order_relaxed);
    return false;
  }
  input->events[tail % kClockQueueCapacity] = event;
  atomic_store_explicit(&input->tail, tail + 1, memory_order_release);
  return true;
}

static bool pop_clock_event(ClockInput *input, ClockEvent *event) {
  uint64_t head = atomic_load_explicit(&input->head, memory_order_relaxed);
  uint64_t tail = atomic_load_explicit(&input->tail, memory_order_acquire);
  if (head == tail) {
    return false;
  }
  *event = input->events[head % kClockQueueCapacity];
  atomic_store_explicit(&input->head, head + 1, memory_order_release);
  return true;
}

static bool clock_queue_empty(ClockInput *input) {
  return atomic_load_explicit(&input->head, memory_order_relaxed) ==
         atomic_load_explicit(&input->tail, memory_order_acquire);
}

static void discard_clock_events(ClockInput *input) {
  ClockEvent ignored;
  while (pop_clock_event(input, &ignored)) {
  }
}

static void enqueue_clock_event(ClockInput *input, int kind,
                                MIDITimeStamp host_time) {
  if (!atomic_load_explicit(&input->listening, memory_order_acquire)) {
    return;
  }
  ClockEvent event = {.kind = kind, .tick = input->tick, .host_time = host_time};
  if (push_clock_event(input, event)) {
    dispatch_semaphore_signal(input->signal);
  }
}

static void handle_system_message(ClockInput *input, UInt32 word,
                                  MIDITimeStamp host_time) {
  switch ((word >> 16) & 0xFF) {
  case kMIDIStart:
    input->tick = -1;
    enqueue_clock_event(input, kClockStart, host_time);
    break;
  case kMIDITimingClock:
    input->tick++;
    enqueue_clock_event(input, kClockTick, host_time);
    break;
  case kMIDIContinue:
    enqueue_clock_event(input, kClockContinue, host_time);
    break;
  case kMIDIStop:
    enqueue_clock_event(input, kClockStop, host_time);
    break;
  case kMIDISongPositionPointer: {
    int64_t sixteenths = ((word >> 8) & 0x7F) | ((word & 0x7F) << 7);
    input->tick = sixteenths * kTicksPerSixteenth - 1;
    break;
  }
  }
}

static void receive_clock(ClockInput *input, const MIDIEventList *event_list) {
  const MIDIEventPacket *packet = &event_list->packet[0];
  for (UInt32 p = 0; p < event_list->numPackets; ++p) {
    MIDITimeStamp host_time =
        packet->timeStamp ? packet->timeStamp : mach_absolute_time();
    UInt32 w = 0;
    while (w < packet->wordCount) {
      UInt32 word = packet->words[w];
      if ((word >> 28) == kUniversalSystemMessage) {
        handle_system_message(input, word, host_time);
      }
      w += universal_message_word_count(word);
    }
    packet = MIDIEventPacketNext(packet);
  }
}

static UInt32 control_change_word(int channel, Byte controller) {
  return ((UInt32)kUniversalMIDI1ChannelVoice << 28) |
         ((UInt32)(kMIDIControlChange | channel) << 16) |
         ((UInt32)controller << 8);
}

static void send_words_now(MIDIPortRef port, MIDIEndpointRef destination,
                           const UInt32 *words, ByteCount word_count) {
  Byte buffer[sizeof(MIDIEventList) + 64 * sizeof(UInt32)];
  MIDIEventList *event_list = (MIDIEventList *)buffer;
  MIDIEventPacket *packet = MIDIEventListInit(event_list, kMIDIProtocol_1_0);
  for (ByteCount i = 0; i < word_count && packet; ++i) {
    packet =
        MIDIEventListAdd(event_list, sizeof buffer, packet, 0, 1, &words[i]);
  }
  MIDISendEventList(port, destination, event_list);
}

static void silence_last_destination(RCoremidiNode *node) {
  if (!node->ports_created || node->disposed || !node->last_destination) {
    return;
  }
  MIDIFlushOutput(node->last_destination);
  UInt32 words[kMIDIChannels * 2];
  for (int channel = 0; channel < kMIDIChannels; ++channel) {
    words[channel * 2] = control_change_word(channel, kMIDIAllSoundOff);
    words[channel * 2 + 1] = control_change_word(channel, kMIDIAllNotesOff);
  }
  send_words_now(node->out, node->last_destination, words, kMIDIChannels * 2);
}

static void dispose_ports(RCoremidiNode *node) {
  if (!node->ports_created || node->disposed) {
    return;
  }
  atomic_store_explicit(&node->clock->listening, false, memory_order_release);
  silence_last_destination(node);
  MIDIPortDispose(node->in);
  MIDIPortDispose(node->out);
  node->disposed = true;
}

static void midi_node_free(void *ptr) {
  RCoremidiNode *node = ptr;
  dispose_ports(node);
  if (node->clock) {
    schedule_clock_input_release(node->clock);
  }
  ruby_xfree(node);
}

static size_t midi_node_memsize(const void *ptr) {
  return sizeof(RCoremidiNode) + sizeof(ClockInput);
}

static const rb_data_type_t midi_node_data_t = {
    "rcoremidi_client",
    {NULL, midi_node_free, midi_node_memsize},
    NULL,
    NULL,
    RUBY_TYPED_FREE_IMMEDIATELY};

static RCoremidiNode *client_node(VALUE self) {
  RCoremidiNode *node;
  TypedData_Get_Struct(self, RCoremidiNode, &midi_node_data_t, node);
  return node;
}

static RCoremidiNode *usable_client_node(VALUE self) {
  RCoremidiNode *node = client_node(self);
  if (!node->ports_created || node->disposed) {
    rb_raise(rb_eRuntimeError, "MIDI client is not available (disposed?)");
  }
  return node;
}

VALUE client_alloc(VALUE klass) {
  RCoremidiNode *node;
  VALUE self =
      TypedData_Make_Struct(klass, RCoremidiNode, &midi_node_data_t, node);
  node->clock = create_clock_input();
  return self;
}

static void wake_clock_waiter(void *ptr) {
  RCoremidiNode *node = ptr;
  dispatch_semaphore_signal(node->clock->signal);
}

static void *wait_for_clock_events(void *ptr) {
  RCoremidiNode *node = ptr;
  if (clock_queue_empty(node->clock) && !atomic_load(&node->stop_requested)) {
    dispatch_semaphore_wait(
        node->clock->signal,
        dispatch_time(DISPATCH_TIME_NOW, kClockWaitNanoseconds));
  }
  return NULL;
}

static void call_optional_handler(VALUE self, ID handler) {
  if (rb_respond_to(self, handler)) {
    rb_funcall(self, handler, 0);
  }
}

static void deliver_clock_event(VALUE self, const ClockEvent *event) {
  VALUE host_time = ULL2NUM(event->host_time);
  switch (event->kind) {
  case kClockStart:
    rb_funcall(self, on_start_intern, 1, host_time);
    break;
  case kClockTick:
    rb_funcall(self, on_tick_intern, 2, LL2NUM(event->tick), host_time);
    break;
  case kClockStop:
    call_optional_handler(self, on_stop_intern);
    break;
  case kClockContinue:
    call_optional_handler(self, on_continue_intern);
    break;
  }
}

static void deliver_clock_events(VALUE self, RCoremidiNode *node) {
  ClockEvent event;
  while (!atomic_load(&node->stop_requested) &&
         pop_clock_event(node->clock, &event)) {
    deliver_clock_event(self, &event);
  }
}

static VALUE run_clock(VALUE self) {
  RCoremidiNode *node = client_node(self);
  while (!atomic_load(&node->stop_requested)) {
    rb_thread_call_without_gvl2(wait_for_clock_events, node, wake_clock_waiter,
                                node);
    deliver_clock_events(self, node);
    rb_thread_check_ints();
  }
  return Qnil;
}

static VALUE finish_clock(VALUE self) {
  RCoremidiNode *node = client_node(self);
  atomic_store_explicit(&node->clock->listening, false, memory_order_release);
  node->running = false;
  return Qnil;
}

VALUE start_client(VALUE self) {
  RCoremidiNode *node = usable_client_node(self);
  if (node->running) {
    rb_raise(rb_eRuntimeError, "MIDI clock already started");
  }
  node->running = true;
  atomic_store(&node->stop_requested, false);
  discard_clock_events(node->clock);
  atomic_store_explicit(&node->clock->listening, true, memory_order_release);
  return rb_ensure(run_clock, self, finish_clock, self);
}

VALUE stop_client(VALUE self) {
  RCoremidiNode *node = client_node(self);
  atomic_store(&node->stop_requested, true);
  if (node->clock) {
    dispatch_semaphore_signal(node->clock->signal);
  }
  return Qnil;
}

VALUE client_running(VALUE self) {
  RCoremidiNode *node = client_node(self);
  return node->clock && atomic_load_explicit(&node->clock->listening,
                                             memory_order_acquire)
             ? Qtrue
             : Qfalse;
}

VALUE silence_client(VALUE self) {
  silence_last_destination(usable_client_node(self));
  return Qnil;
}

VALUE dropped_clock_events(VALUE self) {
  RCoremidiNode *node = client_node(self);
  return ULL2NUM(node->clock ? atomic_load(&node->clock->dropped) : 0);
}

VALUE connect_to(VALUE self, VALUE source) {
  RCoremidiNode *node = usable_client_node(self);
  raise_on_midi_error(
      MIDIPortConnectSource(node->in, *get_midi_data(source), NULL),
      "Could not connect the input port to the MIDI source");
  rb_iv_set(self, "@source", source);
  return Qtrue;
}

static Byte midi_byte(VALUE value) {
  int byte = NUM2INT(value);
  if (byte < 0 || byte > 0xFF) {
    rb_raise(rb_eArgError, "MIDI byte out of range: %d", byte);
  }
  return (Byte)byte;
}

static ByteCount universal_words_for(VALUE message, UInt32 *words) {
  Check_Type(message, T_ARRAY);
  long length = RARRAY_LEN(message);
  if (length == 0 || length > kMaxMIDIMessageLength) {
    rb_raise(rb_eArgError, "MIDI message too long or empty: %ld bytes (max %d)",
             length, kMaxMIDIMessageLength);
  }
  Byte bytes[kMaxMIDIMessageLength];
  for (long i = 0; i < length; ++i) {
    bytes[i] = midi_byte(rb_ary_entry(message, i));
  }
  return universal_words_from_bytes(bytes, (ByteCount)length, words);
}

static UInt64 schedule_offset_in_nanoseconds(VALUE nanoseconds) {
  long long offset = NUM2LL(nanoseconds);
  if (offset < 0 || offset > kMaxScheduleAheadNanoseconds) {
    rb_raise(rb_eArgError, "MIDI timestamp out of range: %lld ns", offset);
  }
  return (UInt64)offset;
}

static void schedule_message(ScheduledMessage *scheduled, long position,
                             enum ReleaseOrder release_order, VALUE message,
                             VALUE nanoseconds, UInt64 base_host_time) {
  scheduled->position = position;
  scheduled->release_order = release_order;
  scheduled->word_count = universal_words_for(message, scheduled->words);
  scheduled->timestamp =
      base_host_time +
      AudioConvertNanosToHostTime(schedule_offset_in_nanoseconds(nanoseconds));
}

static int compare_schedule(const void *a, const void *b) {
  const ScheduledMessage *left = a;
  const ScheduledMessage *right = b;
  if (left->timestamp != right->timestamp) {
    return left->timestamp < right->timestamp ? -1 : 1;
  }
  if (left->release_order != right->release_order) {
    return left->release_order < right->release_order ? -1 : 1;
  }
  return (left->position > right->position) -
         (left->position < right->position);
}

static MIDIEventPacket *add_scheduled_message(MIDIEventList *event_list,
                                              MIDIEventPacket *packet,
                                              const ScheduledMessage *message) {
  ByteCount w = 0;
  while (w < message->word_count) {
    ByteCount size = universal_message_word_count(message->words[w]);
    packet = MIDIEventListAdd(event_list, kEventListCapacity, packet,
                              message->timestamp, size, &message->words[w]);
    if (!packet) {
      rb_raise(rb_eArgError, "Too many MIDI events for one event list");
    }
    w += size;
  }
  return packet;
}

static void fill_event_list(MIDIEventList *event_list,
                            const ScheduledMessage *messages, long count) {
  MIDIEventPacket *packet = MIDIEventListInit(event_list, kMIDIProtocol_1_0);
  for (long i = 0; i < count; ++i) {
    packet = add_scheduled_message(event_list, packet, &messages[i]);
  }
}

VALUE send_packets(int argc, VALUE *argv, VALUE self) {
  VALUE destination, events, base_host_time;
  rb_scan_args(argc, argv, "21", &destination, &events, &base_host_time);
  RCoremidiNode *node = usable_client_node(self);
  MIDIEndpointRef endpoint = *get_midi_data(destination);
  Check_Type(events, T_ARRAY);
  UInt64 base = NIL_P(base_host_time) ? AudioGetCurrentHostTime()
                                      : NUM2ULL(base_host_time);

  long event_count = RARRAY_LEN(events);
  long message_count = event_count * 2;
  VALUE messages_owner, event_list_owner;
  ScheduledMessage *messages = ALLOCV_N(ScheduledMessage, messages_owner,
                                        message_count ? message_count : 1);
  for (long i = 0; i < event_count; ++i) {
    VALUE event = rb_ary_entry(events, i);
    schedule_message(&messages[2 * i], 2 * i, kAttackAfterRelease,
                     rb_funcall(event, on_intern, 0),
                     rb_funcall(event, on_timestamp_intern, 0), base);
    schedule_message(&messages[2 * i + 1], 2 * i + 1, kReleaseFirst,
                     rb_funcall(event, off_intern, 0),
                     rb_funcall(event, off_timestamp_intern, 0), base);
  }
  mergesort(messages, message_count, sizeof *messages, compare_schedule);

  MIDIEventList *event_list = ALLOCV(event_list_owner, kEventListCapacity);
  fill_event_list(event_list, messages, message_count);
  OSStatus status = MIDISendEventList(node->out, endpoint, event_list);
  node->last_destination = endpoint;

  ALLOCV_END(event_list_owner);
  ALLOCV_END(messages_owner);
  raise_on_midi_error(status, "Could not send MIDI events");
  return Qnil;
}

static CFStringRef cf_string_from_ruby(VALUE string) {
  CFStringRef cf_string = CFStringCreateWithCString(
      NULL, StringValueCStr(string), kCFStringEncodingUTF8);
  if (!cf_string) {
    rb_raise(rb_eArgError, "MIDI client name must be valid UTF-8");
  }
  return cf_string;
}

static OSStatus create_input_port(MIDIClientRef client, CFStringRef name,
                                  ClockInput *input, MIDIPortRef *port) {
  return MIDIInputPortCreateWithProtocol(
      client, name, kMIDIProtocol_1_0, port,
      ^(const MIDIEventList *event_list, void *source_ref) {
        atomic_fetch_add(&input->receiving, 1);
        receive_clock(input, event_list);
        atomic_fetch_sub(&input->receiving, 1);
      });
}

static void create_ports(RCoremidiNode *node, MIDIClientRef client,
                         CFStringRef name) {
  OSStatus status = create_input_port(client, name, node->clock, &node->in);
  if (status == noErr) {
    status = MIDIOutputPortCreate(client, name, &node->out);
    if (status != noErr) {
      MIDIPortDispose(node->in);
    }
  }
  CFRelease(name);
  raise_on_midi_error(status, "Could not create the MIDI ports");
  node->ports_created = true;
}

VALUE client_init(VALUE self, VALUE name) {
  RCoremidiNode *node = client_node(self);
  if (node->ports_created) {
    rb_raise(rb_eRuntimeError, "MIDI client already initialized");
  }
  if (!node->clock) {
    rb_raise(rb_eNoMemError, "Could not allocate the MIDI clock input");
  }
  MIDIClientRef client = shared_midi_client();
  create_ports(node, client, cf_string_from_ruby(name));
  rb_iv_set(self, "@name", name);
  return self;
}

VALUE dispose_client(VALUE self) {
  RCoremidiNode *node = client_node(self);
  stop_client(self);
  dispose_ports(node);
  return self;
}
