require 'spec_helper'
require 'rcoremidi/cli'

RSpec.describe RCoreMidi::CLI do

  let(:new_command) { spy(RCoreMidi::Commands::New) }
  let(:command)     {  }
  subject { described_class.new('new') }

  describe 'new' do
    before do
      expect(RCoreMidi::Commands::New).to receive(:new).and_return(new_command)
    end

    let(:argv) { ['new', 'dummy'] }

    it 'call the new application generator' do
      subject.run(argv)
      expect(new_command).to have_received(:run)
    end
  end
end
