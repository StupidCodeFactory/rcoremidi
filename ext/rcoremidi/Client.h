#ifndef CLIENT_H
#define CLIENT_H
#endif



VALUE client_init(int argc, VALUE *argv, VALUE self);
VALUE connect_to(VALUE self, VALUE source);
VALUE dispose_client(VALUE self);
void printProofTwo();

