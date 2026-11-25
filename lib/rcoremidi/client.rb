module RCoreMidi
  # A CoreMIDI client that follows an external MIDI clock and sends notes.
  #
  # The C extension defines the driver methods:
  #
  # * <tt>new(name)</tt>, <tt>name</tt>
  # * <tt>connect_to(source)</tt>: listen to a Source's MIDI clock
  # * <tt>start</tt>: block the calling thread and dispatch clock events to
  #   the hooks below until +stop+ or +dispose+ is called
  # * <tt>stop</tt>, <tt>running?</tt>, <tt>dispose</tt>
  # * <tt>send_packets(destination, notes, base_host_time = now)</tt>: schedule
  #   each note (see TimedNote) relative to +base_host_time+
  # * <tt>silence</tt>: unschedule pending packets and send All Sound Off and
  #   All Notes Off on all 16 channels of the last destination
  # * <tt>dropped_clock_events</tt>: clock events lost because Ruby fell behind
  #
  # This class adds the Ruby side: endpoints to work with and no-op hooks that
  # subclasses override. The hooks run on the thread that called +start+.
  class Client
    # MIDI clock resolution: the clock sends 24 ticks per quarter note.
    TICKS_PER_QUARTER = 24

    # What send_packets reads for each note it sends.
    #
    # * +on+, +off+: MIDI 1.0 message bytes, e.g. <tt>[0x90, 60, 100]</tt> and
    #   <tt>[0x80, 60, 0]</tt>
    # * +on_timestamp+, +off_timestamp+: nanoseconds after the base host time
    #   given to send_packets (non-negative Integers)
    #
    # Any object responding to these four methods works; this Struct is the
    # canonical shape.
    TimedNote = Struct.new(:on, :on_timestamp, :off, :off_timestamp)

    # The Source whose clock this client follows, and the Destination it
    # sends notes to.
    attr_accessor :midi_in, :midi_out

    # Called on MIDI Start (0xFA). +host_time+ is the CoreMIDI host time of
    # the message; the next clock is tick 0.
    def on_start(host_time); end

    # Called on each MIDI Clock (0xF8) while running. +tick+ counts clocks
    # since Start (or the Song Position Pointer), +host_time+ is when the
    # clock message arrived.
    def on_tick(tick, host_time); end

    # Called on MIDI Stop (0xFC).
    def on_stop; end

    # Called on MIDI Continue (0xFB).
    def on_continue; end

    # Listens to the clock of +midi_in+.
    def connect!
      connect_to midi_in
    end
  end
end
