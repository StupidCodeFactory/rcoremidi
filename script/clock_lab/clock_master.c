#include <CoreAudio/HostTime.h>
#include <CoreMIDI/CoreMIDI.h>
#include <mach/mach_time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

enum { kTicksPerBar = 96 };

static MIDIClientRef client;
static MIDIPortRef port;
static MIDIEndpointRef destination;
static UInt64 cursor_ns;

static MIDIEndpointRef find_destination(const char *wanted) {
  for (ItemCount i = 0; i < MIDIGetNumberOfDestinations(); ++i) {
    MIDIEndpointRef endpoint = MIDIGetDestination(i);
    CFStringRef name = NULL;
    char buffer[256] = "";
    MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &name);
    if (name) {
      CFStringGetCString(name, buffer, sizeof buffer, kCFStringEncodingUTF8);
      CFRelease(name);
    }
    if (strstr(buffer, wanted)) {
      return endpoint;
    }
  }
  return 0;
}

static void send_at(UInt64 at_ns, const UInt32 *words, UInt32 count) {
  Byte buffer[256];
  MIDIEventList *list = (MIDIEventList *)buffer;
  MIDIEventPacket *packet = MIDIEventListInit(list, kMIDIProtocol_1_0);
  MIDIEventListAdd(list, sizeof buffer, packet,
                   AudioConvertNanosToHostTime(at_ns), count, words);
  MIDISendEventList(port, destination, list);
}

static void send_system(UInt64 at_ns, Byte status) {
  UInt32 word = 0x10000000 | ((UInt32)status << 16);
  send_at(at_ns, &word, 1);
}

static void sleep_until_shortly_before(UInt64 at_ns) {
  UInt64 now = AudioConvertHostTimeToNanos(mach_absolute_time());
  UInt64 lead = 200000000ULL;
  if (at_ns > now + lead) {
    usleep((useconds_t)((at_ns - now - lead) / 1000));
  }
}

static void play_bars(double bpm, int bars, Byte first_status) {
  double tick_ns = 60e9 / (bpm * 24.0);
  UInt64 section_start = cursor_ns;
  for (int tick = 0; tick < bars * kTicksPerBar; ++tick) {
    UInt64 at = section_start + (UInt64)(tick * tick_ns);
    if (tick % kTicksPerBar == 0) {
      sleep_until_shortly_before(at);
    }
    if (tick == 0 && first_status) {
      UInt32 words[2] = {0x10000000 | ((UInt32)first_status << 16),
                         0x10F80000};
      send_at(at, words, 2);
    } else {
      send_system(at, 0xF8);
    }
  }
  cursor_ns = section_start + (UInt64)(bars * kTicksPerBar * tick_ns);
  fprintf(stderr, "sent %d bars at %.1f bpm\n", bars, bpm);
}

int main(int argc, char **argv) {
  double first_bpm = argc > 1 ? atof(argv[1]) : 120.0;
  double second_bpm = argc > 2 ? atof(argv[2]) : 90.0;
  destination = find_destination("Bus 1");
  if (!destination) {
    fprintf(stderr, "No IAC Bus 1 destination\n");
    return 1;
  }
  MIDIClientCreate(CFSTR("clock lab master"), NULL, NULL, &client);
  MIDIOutputPortCreate(client, CFSTR("clock"), &port);

  cursor_ns = AudioConvertHostTimeToNanos(mach_absolute_time()) + 500000000ULL;
  play_bars(first_bpm, 8, 0xFA);
  play_bars(second_bpm, 8, 0);
  send_system(cursor_ns, 0xFC);
  cursor_ns += 2000000000ULL;
  play_bars(second_bpm, 4, 0xFB);
  send_system(cursor_ns, 0xFC);
  sleep_until_shortly_before(cursor_ns + 1000000000ULL);
  fprintf(stderr, "done\n");
  return 0;
}
