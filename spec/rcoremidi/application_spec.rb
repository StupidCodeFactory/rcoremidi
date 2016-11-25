require 'spec_helper'

RSpec.describe RCoreMidi::Application do
  let(:app_path) { RCoreMidi::AppPathname.new(Dir.pwd) }
  let(:pid_file) { Pathname.new('tmps/pids/arcx.pid') }
  let(:log_file) { Pathname.new('tmps/arcx.log') }
  let(:connections_file) { double(Pathname, read: '') }
  let(:client) { spy(RCoreMidi::Client) }
  let(:midi_in) { double(RCoreMidi::Source) }
  let(:midi_out) { double(RCoreMidi::Destination) }
  subject { described_class.new(app_path) }
  let(:pid_file_content) { StringIO.new }
  describe '#run' do
    before do
    end

    it "writes the pid file" do
      expect(RCoreMidi::AppPathname).to receive(:new).and_return(app_path)
      expect(app_path).to receive(:connections_file).and_return(connections_file)
      expect(YAML).to receive(:load).and_return('midi_in' => 123, 'midi_out' => 456)

      expect(app_path).to receive(:clip_files).and_return([])
      expect(app_path).to receive(:instrument_files).and_return([])
      expect(app_path).to receive(:pid_file).and_return(pid_file).twice

      expect(pid_file).to receive(:exist?).and_return true
      expect(pid_file).to receive(:open).and_yield(pid_file_content)
      expect(pid_file_content).to receive(:write).with(Process.pid.to_s)

      expect(RCoreMidi::Client).to receive(:new).and_return(client)
      expect(client).to receive(:create_live).with(120)

      allow(subject).to receive(:redirect_output)
      expect(subject).to receive(:midi_in).and_return(midi_in)
      expect(subject).to receive(:midi_out).and_return(midi_out)

      expect(Process).to receive(:daemon).and_return(9999)
      expect(subject).to receive(:wait_for_start)
      subject.run(true)
    end

  end
end
