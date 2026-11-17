TICKS_PER_QUARTER = 24
TICKS_PER_BAR = 96
ALL_NOTES_OFF = 123

Event = Struct.new(:arrival, :stamp, :word) do
  def message_type = word >> 28
  def status = (word >> 16) & 0xFF
  def data1 = (word >> 8) & 0xFF
  def data2 = word & 0xFF
  def system?(byte) = message_type == 1 && status == byte
  def note_on? = message_type == 2 && (status & 0xF0) == 0x90 && data2.positive?
  def note_off? = message_type == 2 && ((status & 0xF0) == 0x80 || ((status & 0xF0) == 0x90 && data2.zero?))
  def all_notes_off? = message_type == 2 && (status & 0xF0) == 0xB0 && data1 == ALL_NOTES_OFF
end

events = ARGF.each_line.map do |line|
  arrival, stamp, word = line.split
  Event.new(arrival.to_i, stamp.to_i, word.to_i(16))
end.each_with_index.sort_by { |event, arrival_order| [event.stamp, arrival_order] }.map(&:first)

ticks = []
tick = nil
pass = 0
transport = []
events.each do |event|
  if event.system?(0xFA)
    tick = -1
    transport << [:start, event.stamp]
  elsif event.system?(0xF2)
    tick = ((event.data1 | (event.data2 << 7)) * 6) - 1
    pass += 1 if ticks.any?
  elsif event.system?(0xFB)
    transport << [:continue, event.stamp]
  elsif event.system?(0xFC)
    transport << [:stop, event.stamp]
  elsif event.system?(0xF8) && tick
    tick += 1
    ticks << [tick, event.stamp, pass]
  end
end
abort 'No Start message seen' if ticks.empty?

def tick_position(ticks, time)
  index = ticks.bsearch_index { |(_, stamp)| stamp > time }
  return nil if index.nil? || index.zero?

  (before_tick, before_time, pass), (after_tick, after_time) = ticks[index - 1], ticks[index]
  return nil unless after_tick == before_tick + 1

  following_tick, following_time = ticks[index + 1]
  period = following_tick == after_tick + 1 ? following_time - after_time : after_time - before_time
  [after_tick - ((after_time - time).to_f / period), period, pass]
end

def playing_at?(transport, ticks, time)
  state = transport.select { |(_, stamp)| stamp <= time }.last
  next_tick = ticks.find { |(_, stamp)| stamp > time }
  cut_by_stop = transport.any? { |(kind, stamp)| kind == :stop && stamp >= time && (next_tick.nil? || stamp < next_tick[1]) }
  state && state.first != :stop && !cut_by_stop
end

ms = ->(nanoseconds) { nanoseconds / 1_000_000.0 }

note_ons = events.select(&:note_on?)
accent = note_ons.map(&:data1).max
puts "Ticks: #{ticks.size}   note-ons: #{note_ons.size}   accent note: #{accent}"
puts "Transport: #{transport.map { |(kind, stamp)| "#{kind}@#{format('%.3f', ms.(stamp - transport.first[1]) / 1000)}s" }.join(' ')}"
puts "Max delivery lateness: #{format('%.3f', ms.(events.map { |e| e.arrival - e.stamp }.max))} ms"
puts

per_bar = Hash.new { |hash, bar| hash[bar] = { notes: 0, accents: 0, worst: 0.0 } }
ticks.each { |(tick, _, pass)| per_bar[[pass, (tick / TICKS_PER_BAR) + 1]] if (tick % TICKS_PER_BAR).zero? }
tick_times = {}
ticks.each { |(tick, stamp, pass)| tick_times[[pass, tick]] ||= stamp }
stray = []
note_ons.each do |note|
  position, period, pass = tick_position(ticks, note.stamp)
  next stray << note unless position && playing_at?(transport, ticks, note.stamp)

  quarter_tick = (position / TICKS_PER_QUARTER).round * TICKS_PER_QUARTER
  expected_time = tick_times[[pass, quarter_tick]]
  error = expected_time ? ms.(note.stamp - expected_time) : ms.((position - quarter_tick) * period)
  stats = per_bar[[pass, (quarter_tick / TICKS_PER_BAR) + 1]]
  stats[:notes] += 1
  stats[:accents] += 1 if note.data1 == accent && (quarter_tick % TICKS_PER_BAR).zero?
  stats[:worst] = error if error.abs > stats[:worst].abs
end

puts 'pass  bar  notes  downbeat-accent  worst-offset-ms'
per_bar.sort.each do |(pass, bar), stats|
  puts format('%4d  %3d  %5d  %15s  %+10.3f', pass + 1, bar, stats[:notes], stats[:accents] == 1 ? 'yes' : 'NO', stats[:worst])
end

puts
puts "Notes outside the clock or while stopped: #{stray.size}"
sounding = Hash.new(0)
events.each do |event|
  if event.note_on? then sounding[event.data1] += 1
  elsif event.note_off? then sounding[event.data1] -= 1 if sounding[event.data1].positive?
  elsif event.all_notes_off? then sounding.clear
  end
end
puts "Notes still sounding at the end: #{sounding.values.sum}"
