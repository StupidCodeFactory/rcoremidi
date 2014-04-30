#ifndef SOURCE_H
#define SOURCE_H

/* VALUE source_alloc(VALUE klass); */
/* VALUE source_init(VALUE self, VALUE name); */

/* void   midi_endpoint_free(void *ptr); */
/* size_t midi_endpoint_memsize(const void *ptr); */
/* void   midi_endpoint_mark(void *ptr); */

extern const rb_data_type_t midi_endpoint_data_t;

#endif
