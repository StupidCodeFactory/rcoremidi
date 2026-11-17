require 'spec_helper'
require 'rcoremidi/cli'
require 'tmpdir'

RSpec.describe RCoreMidi::Commands::Generate do
  around do |example|
    Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
  end

  describe 'clip' do
    it 'writes a clip registered under the given name' do
      expect { RCoreMidi::CLI.start(%w[generate clip drum]) }.to output.to_stdout

      expect(File.read(File.join('clips', 'drum.rb'))).to include('RCoreMidi::Clip.register :drum do')
    end
  end
end
