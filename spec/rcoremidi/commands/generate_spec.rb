require 'spec_helper'
require 'rcoremidi/cli'

RSpec.describe RCoreMidi::Commands::Generate do
  include FileUtils::Verbose

  subject { Rcoremidi::CLI.new('spec') }

  let(:argv) { ['generate clip drum'] }
  let(:generate_command) { spy(described_class) }

  before do
    expect(described_class).to receive(:new).and_return(generate_command)
  end

  it 'calls the appropriate subcommand' do
    described_class.run(argv)
    expect(generate_command).to have_received(:execute)
  end

end
