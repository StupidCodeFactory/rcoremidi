#ifndef _MIDI_OBJECT_H_
#define _MIDI_OBJECT_H_

VALUE midi_object_alloc(VALUE klass);
VALUE find_by_unique_id(VALUE klass, VALUE uid);
VALUE find_all(VALUE klass);
#endif /* _MIDI_OBJECT_H_ */
