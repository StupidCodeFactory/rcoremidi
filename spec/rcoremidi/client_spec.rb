require 'spec_helper'

RSpec.describe RCoreMidi::Client do
  subject(:client) { described_class.new('ruby_client') }

  let(:live) { instance_double(RCoreMidi::Live) }
  let(:midi_out) { instance_double(RCoreMidi::Destination) }
  let(:bar_notes) { [instance_double(RCoreMidi::Note)] }
  let(:start_time) { 1_000_000 }
  let(:tick_period) { 500 }

  before do
    client.midi_out = midi_out
    allow(client).to receive(:live).and_return(live)
    allow(live).to receive(:generate_beats).and_return(bar_notes)
    allow(client).to receive(:send_packets)
  end

  after { client.dispose }

  def host_time_of(tick)
    start_time + ((tick + 1) * tick_period)
  end

  def play_ticks(ticks)
    ticks.each { |tick| client.on_tick(tick, host_time_of(tick)) }
  end

  describe '#on_start' do
    it 'schedules the first bar from the start message time' do
      client.on_start(start_time)

      expect(live).to have_received(:generate_beats).with(bar: 1)
      expect(client).to have_received(:send_packets).with(midi_out, bar_notes, start_time)
    end
  end

  describe '#on_tick' do
    before { client.on_start(start_time) }

    it 'schedules the next bar one beat ahead, at its projected downbeat' do
      play_ticks(0..72)

      expect(live).to have_received(:generate_beats).with(bar: 2)
      expect(client).to have_received(:send_packets).with(midi_out, bar_notes, host_time_of(96))
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

  describe '#on_stop' do
    it 'silences notes already scheduled' do
      allow(client).to receive(:silence)

      client.on_stop

      expect(client).to have_received(:silence)
    end
  end
end
