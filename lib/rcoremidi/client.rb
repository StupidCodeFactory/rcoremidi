module RCoreMidi
  class Client
    TICKS_PER_BAR = 96
    TICKS_PER_QUARTER = 24
    BAR_PREPARATION_TICKS = 24
    NOTE_LOOKAHEAD_TICKS = 3
    TICK_PERIOD_SMOOTHING = 4
    TICK_POSITION_PRECISION = 3
    MINIMUM_CLOCK_INTERVAL_NANOSECONDS = 2_000_000
    NANOSECONDS_PER_MINUTE = 60_000_000_000.0

    ScheduledNote = Struct.new(:on, :on_timestamp, :off, :off_timestamp)
    PendingNote = Struct.new(:on, :on_tick, :off, :off_tick)

    attr_accessor :midi_in, :midi_out

    def on_start(_host_time)
      self.playing = true
      self.pending_notes = []
      prepare_bar(1)
    end

    def on_continue
      self.playing = true
      self.pending_notes = []
      self.prepared_bar = nil
    end

    def on_tick(tick, host_time)
      measure_tick_period(tick, host_time)
      return unless playing

      resume_at(tick) unless prepared_bar
      prepare_bar(prepared_bar + 1) while bar_at(tick + BAR_PREPARATION_TICKS) > prepared_bar
      send_due_notes(tick, host_time)
    end

    def on_stop
      self.playing = false
      self.pending_notes = []
      forget_clock_tempo
      silence
    end

    def create_live
      connect!
    end

    def live
      @live ||= Live.new
    end

    private

    attr_accessor :playing, :prepared_bar, :pending_notes, :last_tick, :last_tick_host_time, :last_interval,
                  :tick_period

    def resume_at(tick)
      prepare_bar(bar_at(tick))
      pending_notes.reject! { |note| note.on_tick < tick }
    end

    def prepare_bar(bar)
      first_tick = first_tick_of(bar)
      notes = notes_for_bar(bar).map do |note|
        PendingNote.new(note.on, first_tick + ticks_in(note.on_timestamp),
                        note.off, first_tick + ticks_in(note.off_timestamp))
      end
      self.pending_notes = (pending_notes + notes).sort_by(&:on_tick)
      self.prepared_bar = bar
    end

    def notes_for_bar(bar)
      live.generate_beats(bar: bar).flatten.compact
    end

    def ticks_in(offset_nanoseconds)
      (offset_nanoseconds / configured_tick_nanoseconds).round(TICK_POSITION_PRECISION)
    end

    def send_due_notes(tick, host_time)
      due_notes = take_due_notes(tick)
      return if due_notes.empty?

      send_packets(midi_out, due_notes.map { |note| timed_from(tick, note) }, host_time)
    end

    def take_due_notes(tick)
      horizon = tick_period ? tick + NOTE_LOOKAHEAD_TICKS : tick
      due_count = pending_notes.index { |note| note.on_tick > horizon } || pending_notes.size
      pending_notes.shift(due_count)
    end

    def timed_from(tick, note)
      on_timestamp = ([note.on_tick - tick, 0].max * tick_nanoseconds).round
      off_timestamp = on_timestamp + ((note.off_tick - note.on_tick) * tick_nanoseconds).round
      ScheduledNote.new(note.on, on_timestamp, note.off, off_timestamp)
    end

    def tick_nanoseconds
      tick_period ? HostTime.to_nanoseconds(tick_period) : configured_tick_nanoseconds
    end

    def configured_tick_nanoseconds
      NANOSECONDS_PER_MINUTE / (Application.config.bpm * TICKS_PER_QUARTER)
    end

    def measure_tick_period(tick, host_time)
      interval = host_time - last_tick_host_time if last_tick && tick == last_tick + 1
      record_tick_interval(interval) if full_clock_interval?(interval)
      self.last_interval = interval
      self.last_tick = tick
      self.last_tick_host_time = host_time
    end

    def full_clock_interval?(interval)
      plausible_clock_interval?(interval) && plausible_clock_interval?(last_interval)
    end

    def plausible_clock_interval?(interval)
      interval&.positive? && HostTime.to_nanoseconds(interval) >= MINIMUM_CLOCK_INTERVAL_NANOSECONDS
    end

    def record_tick_interval(interval)
      self.tick_period = tick_period ? smoothed(tick_period, interval) : interval
    end

    def forget_clock_tempo
      self.last_tick = nil
      self.last_interval = nil
      self.tick_period = nil
    end

    def smoothed(average, sample)
      ((average * (TICK_PERIOD_SMOOTHING - 1)) + sample) / TICK_PERIOD_SMOOTHING
    end

    def bar_at(tick)
      (tick / TICKS_PER_BAR) + 1
    end

    def first_tick_of(bar)
      (bar - 1) * TICKS_PER_BAR
    end

    def connect!
      connect_to midi_in
    end
  end
end
