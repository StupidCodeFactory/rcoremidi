#include <CoreAudio/HostTime.h>
#include <CoreMIDI/CoreMIDI.h>
#include <mach/mach_time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static MIDIEndpointRef find_source(const char *wanted) {
  for (ItemCount i = 0; i < MIDIGetNumberOfSources(); ++i) {
    MIDIEndpointRef source = MIDIGetSource(i);
    CFStringRef name = NULL;
    char buffer[256] = "";
    MIDIObjectGetStringProperty(source, kMIDIPropertyDisplayName, &name);
    if (name) {
      CFStringGetCString(name, buffer, sizeof buffer, kCFStringEncodingUTF8);
      CFRelease(name);
    }
    if (strstr(buffer, wanted)) {
      return source;
    }
  }
  return 0;
}

int main(int argc, char **argv) {
  const char *wanted = argc > 1 ? argv[1] : "Bus 1";
  int seconds = argc > 2 ? atoi(argv[2]) : 120;
  setvbuf(stdout, NULL, _IOLBF, 0);

  MIDIEndpointRef source = find_source(wanted);
  if (!source) {
    fprintf(stderr, "No MIDI source matching \"%s\"\n", wanted);
    return 1;
  }

  MIDIClientRef client;
  MIDIPortRef port;
  MIDIClientCreate(CFSTR("clock lab monitor"), NULL, NULL, &client);
  MIDIInputPortCreateWithProtocol(
      client, CFSTR("monitor"), kMIDIProtocol_1_0, &port,
      ^(const MIDIEventList *list, void *unused) {
        UInt64 arrival = AudioConvertHostTimeToNanos(mach_absolute_time());
        const MIDIEventPacket *packet = &list->packet[0];
        for (UInt32 p = 0; p < list->numPackets; ++p) {
          UInt64 stamp = packet->timeStamp
                             ? AudioConvertHostTimeToNanos(packet->timeStamp)
                             : arrival;
          for (UInt32 w = 0; w < packet->wordCount; ++w) {
            printf("%llu %llu %08x\n", arrival, stamp, packet->words[w]);
          }
          packet = MIDIEventPacketNext(packet);
        }
      });
  MIDIPortConnectSource(port, source, NULL);
  fprintf(stderr, "Monitoring \"%s\" for %d s\n", wanted, seconds);
  sleep(seconds);
  return 0;
}
