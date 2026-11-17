module RCoreMidi
  class Client
    TICKS_PER_BAR = 96
    TICKS_PER_QUARTER = 24
    LOOKAHEAD_TICKS = 24
    TICK_PERIOD_SMOOTHING = 8
    TEMPO_MATCH_TOLERANCE = 0.0001
    NANOSECONDS_PER_MINUTE = 60_000_000_000.0

    ScheduledNote = Struct.new(:on, :on_timestamp, :off, :off_timestamp)

    attr_accessor :midi_in, :midi_out

    def on_start(_host_time)
      self.playing = true
      self.scheduled_bar = 1
      self.first_bar_notes = notes_for_bar(1)
    end

    def on_continue
      self.playing = true
      self.scheduled_bar = nil
    end

    def on_tick(tick, host_time)
      measure_tick_period(tick, host_time)
      return unless playing
      return play_first_bar(host_time) if tick.zero? && first_bar_notes

      self.scheduled_bar ||= bar_at(tick)
      schedule_upcoming_bar(tick, host_time)
    end

    def on_stop
      self.playing = false
      silence
    end

    def create_live
      connect!
    end

    def live
      @live ||= Live.new
    end

    private

    attr_accessor :playing, :scheduled_bar, :first_bar_notes, :last_tick, :last_tick_host_time, :tick_period

    def play_first_bar(host_time)
      send_packets(midi_out, follow_clock_tempo(first_bar_notes), host_time)
      self.first_bar_notes = nil
    end

    def schedule_upcoming_bar(tick, host_time)
      upcoming_bar = bar_at(tick + LOOKAHEAD_TICKS)
      return if tick_period.nil? || upcoming_bar <= scheduled_bar

      self.scheduled_bar = upcoming_bar
      downbeat = host_time + ((first_tick_of(upcoming_bar) - tick) * tick_period)
      send_packets(midi_out, follow_clock_tempo(notes_for_bar(upcoming_bar)), downbeat)
    end

    def notes_for_bar(bar)
      live.generate_beats(bar: bar).flatten.compact
    end

    def follow_clock_tempo(notes)
      scale = tempo_scale
      return notes if (scale - 1).abs < TEMPO_MATCH_TOLERANCE

      notes.map do |note|
        ScheduledNote.new(note.on, (note.on_timestamp * scale).round, note.off, (note.off_timestamp * scale).round)
      end
    end

    def tempo_scale
      return 1.0 unless tick_period

      HostTime.to_nanoseconds(tick_period) / configured_tick_nanoseconds
    end

    def configured_tick_nanoseconds
      NANOSECONDS_PER_MINUTE / (Application.config.bpm * TICKS_PER_QUARTER)
    end

    def measure_tick_period(tick, host_time)
      if last_tick && tick == last_tick + 1
        interval = host_time - last_tick_host_time
        self.tick_period = tick_period ? smoothed(tick_period, interval) : interval
      end
      self.last_tick = tick
      self.last_tick_host_time = host_time
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
