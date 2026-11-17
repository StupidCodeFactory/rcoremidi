#include "rcoremidi.h"

enum UniversalMessageType {
  kUniversalSystem = 0x1,
  kUniversalMIDI1ChannelVoice = 0x2,
  kUniversalSysEx7 = 0x3
};

enum SysExChunk {
  kSysExComplete = 0x0,
  kSysExStart = 0x1,
  kSysExContinue = 0x2,
  kSysExEnd = 0x3
};

enum { kSysExBytesPerChunk = 6, kSystemExclusive = 0xF0, kEndOfExclusive = 0xF7 };

static const ByteCount kWordsPerMessageType[16] = {1, 1, 1, 2, 2, 4, 1, 1,
                                                   2, 2, 2, 3, 3, 4, 4, 4};

ByteCount universal_message_word_count(UInt32 first_word) {
  return kWordsPerMessageType[first_word >> 28];
}

static int data_byte_count(Byte status) {
  switch (status & 0xF0) {
  case 0x80:
  case 0x90:
  case 0xA0:
  case 0xB0:
  case 0xE0:
    return 2;
  case 0xC0:
  case 0xD0:
    return 1;
  }
  switch (status) {
  case 0xF1:
  case 0xF3:
    return 1;
  case 0xF2:
    return 2;
  case 0xF6:
  case 0xF8:
  case 0xFA:
  case 0xFB:
  case 0xFC:
  case 0xFE:
  case 0xFF:
    return 0;
  }
  return -1;
}

static void ensure_capacity(ByteCount needed) {
  if (needed > kMaxUniversalWordsPerMessage) {
    rb_raise(rb_eArgError, "MIDI message too long for one event");
  }
}

static Byte data_byte(const Byte *bytes, ByteCount index) {
  if (bytes[index] > 0x7F) {
    rb_raise(rb_eArgError, "MIDI data byte out of range: %d", bytes[index]);
  }
  return bytes[index];
}

static ByteCount add_short_message(const Byte *bytes, ByteCount length,
                                   ByteCount index, UInt32 *words,
                                   ByteCount word_count) {
  Byte status = bytes[index];
  int data_bytes = data_byte_count(status);
  if (data_bytes < 0) {
    rb_raise(rb_eArgError, "Unsupported MIDI status byte: 0x%02X", status);
  }
  if (index + data_bytes >= length) {
    rb_raise(rb_eArgError, "Incomplete MIDI message for status 0x%02X", status);
  }
  Byte first = data_bytes > 0 ? data_byte(bytes, index + 1) : 0;
  Byte second = data_bytes > 1 ? data_byte(bytes, index + 2) : 0;
  UInt32 type = status >= 0xF0 ? kUniversalSystem : kUniversalMIDI1ChannelVoice;
  ensure_capacity(word_count + 1);
  words[word_count] = (type << 28) | ((UInt32)status << 16) |
                      ((UInt32)first << 8) | second;
  return index + 1 + data_bytes;
}

static void add_sysex_chunk(UInt32 *words, ByteCount word_count,
                            enum SysExChunk chunk, const Byte *payload,
                            ByteCount count) {
  Byte padded[kSysExBytesPerChunk] = {0};
  for (ByteCount i = 0; i < count; ++i) {
    padded[i] = payload[i];
  }
  words[word_count] = ((UInt32)kUniversalSysEx7 << 28) | ((UInt32)chunk << 20) |
                      ((UInt32)count << 16) | ((UInt32)padded[0] << 8) |
                      padded[1];
  words[word_count + 1] = ((UInt32)padded[2] << 24) |
                          ((UInt32)padded[3] << 16) |
                          ((UInt32)padded[4] << 8) | padded[5];
}

static enum SysExChunk sysex_chunk_kind(ByteCount offset, ByteCount count,
                                        ByteCount payload_length) {
  bool first = offset == 0;
  bool last = offset + count >= payload_length;
  if (first && last) {
    return kSysExComplete;
  }
  return first ? kSysExStart : (last ? kSysExEnd : kSysExContinue);
}

static ByteCount add_sysex_message(const Byte *bytes, ByteCount length,
                                   ByteCount index, UInt32 *words,
                                   ByteCount *word_count) {
  ByteCount payload_start = index + 1;
  ByteCount end = payload_start;
  while (end < length && bytes[end] != kEndOfExclusive) {
    data_byte(bytes, end);
    ++end;
  }
  if (end == length) {
    rb_raise(rb_eArgError, "System exclusive message is missing 0xF7");
  }

  ByteCount payload_length = end - payload_start;
  ByteCount offset = 0;
  do {
    ByteCount count = payload_length - offset;
    if (count > kSysExBytesPerChunk) {
      count = kSysExBytesPerChunk;
    }
    ensure_capacity(*word_count + 2);
    add_sysex_chunk(words, *word_count,
                    sysex_chunk_kind(offset, count, payload_length),
                    bytes + payload_start + offset, count);
    *word_count += 2;
    offset += count;
  } while (offset < payload_length);
  return end + 1;
}

ByteCount universal_words_from_bytes(const Byte *bytes, ByteCount length,
                                     UInt32 *words) {
  ByteCount word_count = 0;
  ByteCount index = 0;
  while (index < length) {
    if (bytes[index] < 0x80) {
      rb_raise(rb_eArgError, "MIDI message must start with a status byte");
    }
    if (bytes[index] == kSystemExclusive) {
      index = add_sysex_message(bytes, length, index, words, &word_count);
    } else {
      index = add_short_message(bytes, length, index, words, word_count);
      ++word_count;
    }
  }
  return word_count;
}

static VALUE words_for(VALUE module, VALUE message) {
  Check_Type(message, T_ARRAY);
  long length = RARRAY_LEN(message);
  VALUE bytes_owner, words_owner;
  Byte *bytes = ALLOCV_N(Byte, bytes_owner, length ? length : 1);
  for (long i = 0; i < length; ++i) {
    int byte = NUM2INT(rb_ary_entry(message, i));
    if (byte < 0 || byte > 0xFF) {
      rb_raise(rb_eArgError, "MIDI byte out of range: %d", byte);
    }
    bytes[i] = (Byte)byte;
  }
  UInt32 *words =
      ALLOCV_N(UInt32, words_owner, kMaxUniversalWordsPerMessage);
  ByteCount word_count = universal_words_from_bytes(bytes, length, words);

  VALUE result = rb_ary_new_capa(word_count);
  for (ByteCount i = 0; i < word_count; ++i) {
    rb_ary_push(result, UINT2NUM(words[i]));
  }
  ALLOCV_END(words_owner);
  ALLOCV_END(bytes_owner);
  return result;
}

void init_universal_packet(VALUE rcoremidi_module) {
  VALUE universal_packet =
      rb_define_module_under(rcoremidi_module, "UniversalPacket");
  rb_define_singleton_method(universal_packet, "words_for", words_for, 1);
}
