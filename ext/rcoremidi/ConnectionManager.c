#include "Base.h"

VALUE get_devices()
{
    VALUE arr = rb_ary_new();
    VALUE sources = rb_hash_new();

    int i;
    for(i = 0; i < (int) MIDIGetNumberOfSources(); ++i)
    {
        OSStatus status;
        MIDIEndpointRef *endpoint;
        
        endpoint = ALLOC(MIDIEndpointRef);
        *endpoint = MIDIGetSource((ItemCount)i);
        // printf("\n%d)\nadress:\t%p\n", i, endpoint);

        CFStringRef pname;

        status = MIDIObjectGetStringProperty(*endpoint, kMIDIPropertyDisplayName, &pname);

        if (status == noErr){

            char name[64];

            CFStringGetCString(pname, name, sizeof(name), 0);
            VALUE rName = rb_str_new2(name);
            CFRelease(pname);
            // printf("%s\n", name);

            VALUE obj;

            obj = Data_Wrap_Struct(rb_cEndpoint, 0, free, endpoint);
            /*
            switch (TYPE(obj)) {
                case T_FIXNUM:
                printf("%d\n", FIX2INT(obj));
                break;
                case T_STRING:
                printf("%s\n", StringValue(obj));
                break;
                case T_ARRAY:
                printf("array ?????\n");
                break;
                case T_NIL:
                printf("NIL\n");
                break;
                case T_OBJECT:
                printf("T_OBJECT\n");
                break;
                case T_CLASS:
                printf("T_CLASS\n");
                break;
                case T_DATA:
                printf("T_DATA\n");
                break;
                default:
                rb_raise(rb_eTypeError, "not valid value");
                break;
            }
            */
            rb_hash_aset(sources, INT2FIX(i+1), rb_funcall(rb_cSource, rb_intern("new"), 2, rName, obj));
            rb_ary_push(arr, rb_funcall(rb_cSource, rb_intern("new"), 2, rName, obj));

        }


    }
    return sources;
}

