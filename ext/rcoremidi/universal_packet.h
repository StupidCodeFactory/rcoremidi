#ifndef UNIVERSAL_PACKET_H
#define UNIVERSAL_PACKET_H

enum { kMaxUniversalWordsPerMessage = 256 };

ByteCount universal_words_from_bytes(const Byte *bytes, ByteCount length,
                                     UInt32 *words);
ByteCount universal_message_word_count(UInt32 first_word);
void init_universal_packet(VALUE rcoremidi_module);

#endif
