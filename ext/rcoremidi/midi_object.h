#ifndef _MIDI_OBJECT_H_
#define _MIDI_OBJECT_H_

VALUE midi_object_alloc(VALUE klass);
VALUE find_by_unique_id(VALUE klass, VALUE uid);

#endif /* _MIDI_OBJECT_H_ */
