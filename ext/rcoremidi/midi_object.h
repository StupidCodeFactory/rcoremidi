#ifndef MIDI_OBJECT_H
#define MIDI_OBJECT_H

VALUE midi_object_alloc(VALUE klass);
MIDIObjectRef *get_midi_data(VALUE rb_midi_object);
VALUE find_by_unique_id(VALUE klass, VALUE uid);
VALUE find_all(VALUE klass);

#endif
