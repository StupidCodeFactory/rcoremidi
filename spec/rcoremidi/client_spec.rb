# Runs without the compiled extension: only the Ruby side of Client is loaded.
require 'rspec'
require 'rcoremidi/client'

RSpec.describe RCoreMidi::Client do
  subject(:client) { described_class.allocate }

  it 'knows the MIDI clock resolution' do
    expect(described_class::TICKS_PER_QUARTER).to eq(24)
  end

  it 'has no-op clock hooks for subclasses to override' do
    expect(client.on_start(123)).to be_nil
    expect(client.on_tick(0, 123)).to be_nil
    expect(client.on_stop).to be_nil
    expect(client.on_continue).to be_nil
  end

  it 'holds its MIDI endpoints' do
    client.midi_in = :source
    client.midi_out = :destination
    expect([client.midi_in, client.midi_out]).to eq(%i[source destination])
  end

  it 'connects to its midi_in' do
    client.midi_in = :source
    expect(client).to receive(:connect_to).with(:source).and_return(true)
    expect(client.connect!).to be true
  end

  it 'lets a subclass override the hooks' do
    subclass = Class.new(described_class) do
      def on_tick(tick, _host_time) = (@ticks ||= []) << tick
    end
    instance = subclass.allocate
    instance.on_tick(0, 1)
    expect(instance.on_tick(1, 2)).to eq([0, 1])
  end

  describe RCoreMidi::Client::TimedNote do
    subject(:note) { described_class.new([0x90, 60, 100], 0, [0x80, 60, 0], 500_000_000) }

    it 'exposes what send_packets reads' do
      expect(note.on).to eq([0x90, 60, 100])
      expect(note.on_timestamp).to eq(0)
      expect(note.off).to eq([0x80, 60, 0])
      expect(note.off_timestamp).to eq(500_000_000)
    end
  end
end
