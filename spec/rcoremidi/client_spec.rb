require 'spec_helper'

RSpec.describe RCoreMidi::Client do
  subject(:client) { described_class.new('ruby_client') }

  let(:live) { instance_double(RCoreMidi::Live) }
  let(:midi_out) { instance_double(RCoreMidi::Destination) }
  let(:bar_notes) { [described_class::ScheduledNote.new([0x90, 60, 90], 1_000_000, [0x80, 60, 0], 2_000_000)] }
  let(:start_time) { 1_000_000_000 }
  let(:configured_tick_nanoseconds) { 60_000_000_000 / (RCoreMidi::Application.config.bpm * 24) }
  let(:tick_period) { RCoreMidi::HostTime.from_nanoseconds(configured_tick_nanoseconds) }
  let(:sent) { [] }

  before do
    client.midi_out = midi_out
    allow(client).to receive(:live).and_return(live)
    allow(live).to receive(:generate_beats).and_return(bar_notes)
    allow(client).to receive(:send_packets) { |_destination, notes, host_time| sent << [notes, host_time] }
  end

  after { client.dispose }

  def host_time_of(tick)
    start_time + ((tick + 1) * tick_period)
  end

  def play_ticks(ticks)
    ticks.each { |tick| client.on_tick(tick, host_time_of(tick)) }
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

      it 'plays the first bar from the first clock after start' do
        play_ticks([0])

        expect(sent).to contain_exactly([bar_notes, host_time_of(0)])
      end

      it 'schedules the next bar one beat ahead, at its projected downbeat' do
        play_ticks(0..72)

        expect(live).to have_received(:generate_beats).with(bar: 2)
        expect(sent.last).to eq([bar_notes, host_time_of(96)])
      end

      it 'does not schedule the next bar before the lookahead point' do
        play_ticks(0..71)

        expect(live).to have_received(:generate_beats).once
      end

      it 'schedules each bar only once' do
        play_ticks(0..95)

        expect(live).to have_received(:generate_beats).twice
      end

      it 'still schedules the next bar when the lookahead tick was dropped' do
        play_ticks((0..71).to_a + [73])

        expect(live).to have_received(:generate_beats).with(bar: 2)
      end
    end

    context 'when the clock runs at half the configured tempo' do
      let(:tick_period) { RCoreMidi::HostTime.from_nanoseconds(configured_tick_nanoseconds * 2) }

      before do
        client.on_start(start_time)
        play_ticks(0..72)
      end

      it 'stretches note offsets inside the bar to the clock tempo' do
        notes, = sent.last

        expect(notes.first).to have_attributes(on_timestamp: be_within(1_000).of(2_000_000),
                                               off_timestamp: be_within(1_000).of(4_000_000))
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

    it 'resumes from the next bar instead of replaying the interrupted one' do
      play_ticks(400..456)

      expect(live).to have_received(:generate_beats).with(bar: 6)
      expect(sent.map(&:last)).to eq([host_time_of(480)])
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
  end
end
