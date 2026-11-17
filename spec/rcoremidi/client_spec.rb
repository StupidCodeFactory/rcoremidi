require 'spec_helper'

RSpec.describe RCoreMidi::Client do
  subject(:client) { described_class.new('ruby_client') }

  let(:live) { instance_double(RCoreMidi::Live) }
  let(:midi_out) { instance_double(RCoreMidi::Destination) }
  let(:configured_tick_nanoseconds) { 60_000_000_000.0 / (RCoreMidi::Application.config.bpm * 24) }
  let(:downbeat) { note_at(38, on_tick: 0, off_tick: 6) }
  let(:second_beat) { note_at(37, on_tick: 24, off_tick: 30) }
  let(:start_time) { 1_000_000_000 }
  let(:tick_period) { RCoreMidi::HostTime.from_nanoseconds(configured_tick_nanoseconds) }
  let(:sent) { [] }

  before do
    client.midi_out = midi_out
    allow(client).to receive(:live).and_return(live)
    allow(live).to receive(:generate_beats).and_return([downbeat, second_beat])
    allow(client).to receive(:send_packets) { |_destination, notes, host_time| sent << [notes, host_time] }
  end

  after { client.dispose }

  def note_at(pitch, on_tick:, off_tick:)
    described_class::ScheduledNote.new([0x90, pitch, 90], (on_tick * configured_tick_nanoseconds).round,
                                       [0x80, pitch, 0], (off_tick * configured_tick_nanoseconds).round)
  end

  def host_time_of(tick)
    start_time + ((tick + 1) * tick_period)
  end

  def play_ticks(ticks)
    ticks.each { |tick| client.on_tick(tick, host_time_of(tick)) }
  end

  def clock_ticks(count)
    count * RCoreMidi::HostTime.to_nanoseconds(tick_period)
  end

  def second_beat_sent_three_ticks_ahead
    described_class::ScheduledNote.new(second_beat.on, clock_ticks(3), second_beat.off, clock_ticks(9))
  end

  describe '#on_start' do
    it 'prepares the first bar without sending it yet' do
      client.on_start(start_time)

      expect(live).to have_received(:generate_beats).with(bar: 1)
      expect(sent).to be_empty
    end
  end

  describe '#on_tick' do
    context 'before the clock has started' do
      it 'does not schedule anything' do
        play_ticks(0..200)

        expect(sent).to be_empty
      end
    end

    context 'after the clock has started' do
      before { client.on_start(start_time) }

      it 'plays the downbeat on the first clock after start' do
        play_ticks([0])

        expect(sent).to eq([[[downbeat], host_time_of(0)]])
      end

      it 'sends each note a few clock ticks ahead, timed from the latest clock' do
        play_ticks(0..21)

        expect(sent.last).to eq([[second_beat_sent_three_ticks_ahead], host_time_of(21)])
      end

      it 'does not send a note before its lookahead' do
        play_ticks(0..20)

        expect(sent).to eq([[[downbeat], host_time_of(0)]])
      end

      it 'prepares the next bar one beat ahead' do
        play_ticks(0..72)

        expect(live).to have_received(:generate_beats).with(bar: 2)
      end

      it 'does not prepare the next bar before the preparation point' do
        play_ticks(0..71)

        expect(live).to have_received(:generate_beats).once
      end

      it 'still prepares the next bar when the preparation tick was dropped' do
        play_ticks((0..71).to_a + [73])

        expect(live).to have_received(:generate_beats).with(bar: 2)
      end
    end

    context 'when the clock runs at half the configured tempo' do
      let(:tick_period) { RCoreMidi::HostTime.from_nanoseconds(configured_tick_nanoseconds * 2) }

      before { client.on_start(start_time) }

      it 'times notes from the measured clock tempo' do
        play_ticks(0..21)

        expect(sent.last).to eq([[second_beat_sent_three_ticks_ahead], host_time_of(21)])
      end
    end
  end

  describe '#on_continue' do
    before do
      client.on_start(start_time)
      play_ticks(0..72)
      client.on_stop
      sent.clear
      client.on_continue
    end

    it 'plays the rest of the bar when continuing inside it' do
      play_ticks(400..405)

      expect(live).to have_received(:generate_beats).with(bar: 5)
      expect(sent).to eq([[[second_beat_sent_three_ticks_ahead], host_time_of(405)]])
    end

    it 'plays the bar it resumes on when continuing from a downbeat' do
      play_ticks([480])

      expect(live).to have_received(:generate_beats).with(bar: 6)
      expect(sent).to eq([[[downbeat], host_time_of(480)]])
    end
  end

  describe 'continuing after the tempo changed while stopped' do
    let(:slower_tick_period) { tick_period * 2 }

    before do
      client.on_start(start_time)
      play_ticks(0..72)
      client.on_stop
      client.on_continue
      (480..501).each { |tick| client.on_tick(tick, start_time + ((tick - 480) * slower_tick_period)) }
    end

    it 'times notes from the tempo measured after continuing' do
      three_slower_ticks = 3 * RCoreMidi::HostTime.to_nanoseconds(slower_tick_period)

      expect(sent.last.first).to contain_exactly(have_attributes(on_timestamp: three_slower_ticks,
                                                                 off_timestamp: three_slower_ticks * 3))
    end
  end

  describe 'continuing after the catch-up clocks a DAW sends with Continue' do
    let(:resumed_at) { host_time_of(18) }

    def resumed_host_time_of(tick)
      catch_up_spacing = RCoreMidi::HostTime.from_nanoseconds(200)
      return resumed_at + ((tick - 18) * catch_up_spacing) if tick <= 21

      resumed_at + (tick_period / 2) + ((tick - 22) * tick_period)
    end

    before do
      client.on_start(start_time)
      play_ticks(0..10)
      client.on_stop
      sent.clear
      client.on_continue
      (18..23).each { |tick| client.on_tick(tick, resumed_host_time_of(tick)) }
    end

    it 'times notes only from full clock intervals' do
      expect(sent).to eq([[[described_class::ScheduledNote.new(second_beat.on, clock_ticks(1), second_beat.off,
                                                                clock_ticks(7))], resumed_host_time_of(23)]])
    end
  end

  describe '#on_stop' do
    before { allow(client).to receive(:silence) }

    it 'silences notes already scheduled' do
      client.on_stop

      expect(client).to have_received(:silence)
    end

    it 'stops scheduling bars' do
      client.on_start(start_time)
      client.on_stop
      play_ticks(0..200)

      expect(sent).to be_empty
    end

    it 'does not send a note twice after continuing' do
      client.on_start(start_time)
      play_ticks(0..10)
      client.on_stop
      sent.clear
      client.on_continue
      play_ticks(11..30)

      expect(sent.flat_map(&:first).map(&:on)).to eq([second_beat.on])
    end
  end
end
