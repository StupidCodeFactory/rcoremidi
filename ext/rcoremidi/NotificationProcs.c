// #include "Base.h"
// 
// void MidiReadProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon){
// 
//     MIDIPacket *packet = (MIDIPacket *)pktlist->packet;	// remove const (!)
//     unsigned int j;
//     int i;
// 
//     for (j = 0; j < pktlist->numPackets; ++j) {
//         for (i = 0; i < packet->length; ++i) {
//          printf("count %d :\t%X\n",  packet->length, packet->data[i]);
//     // 
//     //      // rechannelize status bytes
//     //                 //  if (packet->data[i] >= 0x80 && packet->data[i] < 0xF0)
//     //                 //      packet->data[i] = (packet->data[i] & 0xF0) | gChannel;
//     //                 // }
//     // 
//      // packet = MIDIPacketNext(packet);
//         }
//     }
//     
//     if (j > 100) {
//         exit(0);
//     }
// }
