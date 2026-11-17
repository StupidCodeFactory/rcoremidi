#include <CoreMIDI/CoreMIDI.h>
#include <unistd.h>

int main(void) {
  MIDIClientRef client;
  MIDIEndpointRef source;
  MIDIClientCreate(CFSTR("rcoremidi spec helper"), NULL, NULL, &client);
  MIDISourceCreate(client, CFSTR("rcoremidi spec virtual source"), &source);
  sleep(1);
  return 0;
}
