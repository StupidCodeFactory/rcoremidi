require 'spec_helper'
require 'rcoremidi/cli'
require 'tmpdir'

RSpec.describe RCoreMidi::CLI do
  around do |example|
    Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
  end

  describe 'new' do
    it 'generates a new application' do
      expect { described_class.start(%w[new dummy]) }.to output.to_stdout

      expect(File).to be_file(File.join('dummy', 'config', RCoreMidi::Commands::New::APPLICATION))
    end
  end
end
