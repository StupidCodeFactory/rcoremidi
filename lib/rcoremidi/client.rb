module RCoreMidi
  class Client
    TICKS_PER_BAR = 96
    LOOKAHEAD_TICKS = 24
    TICK_PERIOD_SMOOTHING = 8

    attr_accessor :midi_in, :midi_out

    def on_start(host_time)
      self.last_tick = nil
      self.tick_period = nil
      schedule_bar(1, host_time)
    end

    def on_tick(tick, host_time)
      measure_tick_period(tick, host_time)
      upcoming_bar = bar_at(tick + LOOKAHEAD_TICKS)
      return if tick_period.nil? || upcoming_bar <= scheduled_bar

      schedule_bar(upcoming_bar, host_time + ((first_tick_of(upcoming_bar) - tick) * tick_period))
    end

    def on_stop
      silence
    end

    def create_live
      connect!
    end

    def live
      @live ||= Live.new
    end

    private

    attr_accessor :last_tick, :last_tick_host_time, :tick_period
    attr_writer :scheduled_bar

    def scheduled_bar
      @scheduled_bar || 0
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

    def schedule_bar(bar, host_time)
      self.scheduled_bar = bar
      send_packets(midi_out, live.generate_beats(bar: bar).flatten.compact, host_time)
    end

    def connect!
      connect_to midi_in
    end
  end
end
