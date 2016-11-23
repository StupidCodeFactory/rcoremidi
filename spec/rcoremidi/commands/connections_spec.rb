require 'spec_helper'

RSpec.describe RCoreMidi::Commands::Connections do
  let(:app) { 'dummy' }
  let(:stdout) { StringIO.new }
  let(:entity) { spy(RCoreMidi::Entity, name: 'Entity Name') }
  let(:device) {
    spy(RCoreMidi::Device, name: 'Device Name', entities_with_midi_in: [entity], entities_with_midi_out: [entity], )
  }
  before do
    APP_PATH = File.expand_path(app)
    RCoreMidi::Commands::New.start [app]
    allow(entity).to receive(:device).and_return(device)
    allow(RCoreMidi::Device).to receive(:all).and_return([device])

  end

  let(:connection_name) { 'logic_pro' }

  describe 'when not in application' do
    it 'raises an error' do
      expect {
        described_class.start [connection_name]
      }.to raise_error(RuntimeError, "Could not find application root")
    end
  end

  describe 'when in an application' do
    it 'prints device inputs' do
      described_class.start [connection_name]
    end

  end
end
