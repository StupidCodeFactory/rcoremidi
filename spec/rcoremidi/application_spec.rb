require 'spec_helper'
require 'rcoremidi/cli'
require 'tmpdir'

RSpec.describe RCoreMidi::Application do
  let(:fixtures_root) { RCoreMidi::AppPathname.new(File.join('spec', 'fixtures')) }

  describe '.load_clips!' do
    before { allow(described_class).to receive(:root).and_return(fixtures_root) }

    it 'registers the clips found in the clips directory' do
      described_class.load_clips!

      expect(RCoreMidi::Clip[:drum]).to be_an_instance_of(RCoreMidi::Clip)
    end
  end

  describe '.load_instruments!' do
    before do
      allow(described_class).to receive(:root).and_return(fixtures_root)
      described_class.load_clips!
    end

    it 'registers the instruments found in the instruments directory' do
      described_class.load_instruments!

      expect(RCoreMidi::Instrument[:drum]).to be_an_instance_of(RCoreMidi::Instrument)
    end
  end

  describe '#run' do
    let(:client) { spy(RCoreMidi::Client) }

    around do |example|
      Dir.mktmpdir do |dir|
        @app_root = RCoreMidi::AppPathname.new(dir)
        @app_root.pid_dir.mkpath
        @app_root.log_file.dirname.mkpath
        example.run
      end
    end

    before do
      allow(described_class).to receive(:root).and_return(@app_root)
      allow(Process).to receive(:daemon)
      allow(Process).to receive(:setproctitle)
      allow(subject).to receive_messages(
        redirect_output: nil, client: client, midi_in: nil, midi_out: nil, trap: nil, wait_for_start: nil
      )
      allow(subject.config).to receive(:logger=)
    end

    it 'writes the pid file in daemon mode' do
      subject.run(daemon_mode: true)

      expect(@app_root.pid_file.read).to eq(Process.pid.to_s)
    end

    it 'connects the client to the live session' do
      subject.run(daemon_mode: true)

      expect(client).to have_received(:create_live)
    end
  end
end
