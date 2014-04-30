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
VALUE rb_cTimer;


ID new_intern;

VALUE cb_thread;
static ID on_tick_intern;

pthread_mutex_t g_callback_mutex  = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t  g_callback_cond   = PTHREAD_COND_INITIALIZER;
callback_t      *g_callback_queue = NULL;

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

static VALUE wait_for_callback_signal(void * w) {
        callback_waiting_t *waiting = (callback_waiting_t*) w;

        pthread_mutex_lock(&g_callback_mutex);

        while (waiting->abort == false && (waiting->callback = g_callback_queue_pop()) == NULL)
        {
                pthread_cond_wait(&g_callback_cond, &g_callback_mutex);
        }

        pthread_mutex_unlock(&g_callback_mutex);

        return Qnil;
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
                rb_thread_blocking_region(wait_for_callback_signal, &waiting, stop_waiting_for_callback_signal, &waiting);
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
        rb_mRCOREMIDI = rb_define_module("RCoreMidi");

        rb_cMIDIObject = rb_define_class_under(rb_mRCOREMIDI, "MIDIObject", rb_cObject);
        rb_define_singleton_method(rb_cMIDIObject, "find_by_unique_id", find_by_unique_id, 1);

        /*
         * RCoreMidi::Device
         */
        rb_cDevice = rb_define_class_under(rb_mRCOREMIDI, "Device", rb_cObject);
        rb_define_singleton_method(rb_cDevice, "get_number_of_devices", get_number_of_devices, 0);
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
        rb_define_attr(rb_cClient, "name", 1, 1);
        rb_define_attr(rb_cClient, "queue", 1, 1);
        rb_define_attr(rb_cClient, "is_connected", 1, 1);
        rb_define_method(rb_cClient, "on_tick", midi_in_callback, 0);

         cb_thread = rb_thread_create(boot_callback_event_thread, NULL);
         rb_funcall(cb_thread, rb_intern("abort_on_exception="), 1, Qtrue);


        rb_cMidiPacket = rb_define_class_under(rb_mRCOREMIDI, "MidiPacket", rb_cObject);

        /*
         * RCoreMidi::MidiQueue
         */
        rb_cMidiQueue = rb_define_class_under(rb_mRCOREMIDI, "MidiQueue", rb_cObject);
        rb_define_method(rb_cMidiQueue, "initialize", init_midi_queue, 0);
        rb_define_attr(rb_cMidiQueue, "queue", 1, 1);

        /*
         * RCoreMidi::Source
         */
        rb_cConectionManager = rb_define_class_under(rb_mRCOREMIDI, "ConnectionManager", rb_cObject);
        rb_define_singleton_method(rb_cConectionManager, "devices", get_devices, 0);

        /*
         * RCoreMidi::Timer
         */

        rb_cTimer = rb_define_class_under(rb_mRCOREMIDI, "Timer", rb_cObject);
        rb_define_method(rb_cTimer, "initialize", init_timer, 1);
        rb_define_method(rb_cTimer, "start", start_timer, 0);
        rb_define_attr(rb_cTimer, "tempo", 1, 1);

        on_tick_intern = rb_intern("on_tick");
        new_intern = rb_intern("new");
}
