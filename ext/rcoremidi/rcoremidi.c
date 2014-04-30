#include "Base.h"

VALUE rb_mRCOREMIDI;
VALUE rb_cMIDIObject;
VALUE rb_cDevice;
VALUE rb_cEntity;
VALUE rb_cSource;
VALUE rb_cDestination;
VALUE rb_cConectionManager;
VALUE rb_cEndpoint;
VALUE rb_cClient;
VALUE rb_cPort;
VALUE rb_cMidiQueue;
VALUE rb_cMidiPacket;
VALUE cb_thread;

ID new_intern;
ID devices_intern;
ID empty_intern;
ID lock_intern;

static ID on_tick_intern;

pthread_mutex_t g_callback_mutex  = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t  g_callback_cond   = PTHREAD_COND_INITIALIZER;
callback_t      *g_callback_queue = NULL;


void midi_endpoint_free(void *ptr)
{
    MIDIEndpointRef *tmp = ptr;
    if(tmp) {
        free(tmp);
    }
}

size_t midi_endpoint_memsize(const void *ptr)
{
    return ptr ? sizeof(MIDIEndpointRef) : 0;
}


const rb_data_type_t midi_endpoint_data_t = {
    "midi_enpoint",
    0, midi_endpoint_free, midi_endpoint_memsize
};


void g_callback_queue_push(callback_t *callback)
{
        callback->next   = g_callback_queue;
        g_callback_queue = callback;
}

static callback_t *g_callback_queue_pop(void)
{
        callback_t *callback = g_callback_queue;
        if (callback)
        {
                g_callback_queue = callback->next;
        }
        return callback;
}

static void *wait_for_callback_signal(void * w) {
        callback_waiting_t *waiting = (callback_waiting_t*) w;

        pthread_mutex_lock(&g_callback_mutex);

        while (waiting->abort == false && (waiting->callback = g_callback_queue_pop()) == NULL)
        {
                pthread_cond_wait(&g_callback_cond, &g_callback_mutex);
        }

        pthread_mutex_unlock(&g_callback_mutex);

        return NULL;
}

static void stop_waiting_for_callback_signal(void *w)
{
        callback_waiting_t *waiting = (callback_waiting_t*) w;

        pthread_mutex_lock(&g_callback_mutex);
        waiting->abort = true;
        pthread_cond_signal(&g_callback_cond);
        pthread_mutex_unlock(&g_callback_mutex);
}

static VALUE boot_callback_event_thread(void * data) {
        callback_waiting_t waiting = {
                .callback = NULL, .abort = false
        };

        while (waiting.abort == false) {
                rb_thread_call_without_gvl(wait_for_callback_signal, &waiting, stop_waiting_for_callback_signal, &waiting);
                if (waiting.callback)
                {
                        VALUE client = (VALUE)waiting.callback->data;
                        RCoremidiNode *clientNode = client_get_data(client);

                        pthread_mutex_lock(&waiting.callback->mutex);
                        /* rb_funcall(client, on_tick_intern, 0); */
                        rb_funcall(rb_mKernel, rb_intern("puts"), 1, rb_funcall(client, rb_intern("on_tick"), 0));
                        printf ("TRANSPORT: %d\n", clientNode->transport->tick_count);
                        pthread_mutex_unlock(&waiting.callback->mutex);
                }
        }
        return Qnil;
}


void
Init_rcoremidi()
{
        on_tick_intern = rb_intern("on_tick");
        new_intern     = rb_intern("new");
        devices_intern = rb_intern("@@devices");
        empty_intern   = rb_intern("empty?");

        rb_mRCOREMIDI = rb_define_module("RCoreMidi");

        rb_cMIDIObject = rb_define_class_under(rb_mRCOREMIDI, "MIDIObject", rb_cObject);
        rb_define_singleton_method(rb_cMIDIObject, "find_by_unique_id", find_by_unique_id, 1);

        /*
         * RCoreMidi::Device
         */
        rb_cDevice = rb_define_class_under(rb_mRCOREMIDI, "Device", rb_cObject);
        /* rb_define_singleton_method(rb_cDevice, "get_number_of_devices", get_number_of_devices, 0); */
        rb_cvar_set(rb_cDevice, devices_intern, rb_ary_new());
        rb_cvar_set(rb_cDevice, lock_intern, rb_mutex_new());
        rb_define_singleton_method(rb_cDevice, "all", find_all, 0);
        rb_define_alloc_func(rb_cDevice, midi_object_alloc);
        rb_define_attr(rb_cDevice, "name", 1, 0);
        rb_define_attr(rb_cDevice, "driver", 1, 0);
        rb_define_attr(rb_cDevice, "manufacturer", 1, 0);
        rb_define_attr(rb_cDevice, "uid", 1, 0);
        rb_define_attr(rb_cDevice, "entities", 1, 0);


        /*
         * RCoreMidi::Entity
         */
        rb_cEntity = rb_define_class_under(rb_mRCOREMIDI, "Entity", rb_cObject);
        rb_define_alloc_func(rb_cDevice, midi_object_alloc);
        rb_define_attr(rb_cEntity, "uid", 1, 0);
        rb_define_attr(rb_cEntity, "name", 1, 0);
        rb_define_attr(rb_cEntity, "endpoints", 1, 0);

        /*
         * RCoreMidi::Source
         */
        rb_cSource = rb_define_class_under(rb_mRCOREMIDI, "Source", rb_cObject);
        rb_define_alloc_func(rb_cSource, midi_object_alloc);
        rb_define_attr(rb_cSource, "uid", 1, 0);

        /*
         * RCoreMidi::Destination
         */
        rb_cDestination = rb_define_class_under(rb_mRCOREMIDI, "Destination", rb_cObject);
        rb_define_alloc_func(rb_cDestination, midi_object_alloc);
        rb_define_attr(rb_cDestination, "uid", 1, 0);

        /*
         * RCoreMidi::Endpoint
         */
        rb_cEndpoint =  rb_define_class_under(rb_mRCOREMIDI, "Endpoint", rb_cObject);

        /*
         * RCoreMidi::Port
         */
        rb_cPort =  rb_define_class_under(rb_mRCOREMIDI, "Port", rb_cObject);
        rb_define_method(rb_cPort, "initialize", port_init, 0);
        rb_define_attr(rb_cPort, "port_ref", 1, 0);
        /*
         * RCoreMidi::Client
         */

        rb_cClient =  rb_define_class_under(rb_mRCOREMIDI, "Client", rb_cObject);
        rb_define_alloc_func(rb_cClient, client_alloc);
        rb_define_method(rb_cClient, "initialize", client_init, -1);
        rb_define_method(rb_cClient, "connect_to", connect_to, 1);
        rb_define_method(rb_cClient, "dispose", dispose_client, 0);
        rb_define_method(rb_cClient, "on_tick", midi_in_callback, 0);
        rb_define_attr(rb_cClient, "name", 1, 1);
        rb_define_attr(rb_cClient, "is_connected", 1, 1);

         cb_thread = rb_thread_create(boot_callback_event_thread, NULL);
         rb_funcall(cb_thread, rb_intern("abort_on_exception="), 1, Qtrue);

}
