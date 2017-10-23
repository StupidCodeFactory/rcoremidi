require 'spec_helper'
require 'rcoremidi/cli'

RSpec.describe RCoreMidi::Commands::New  do

  include FileUtils::Verbose

  let(:application_name) { 'dummy_app' }

  let(:created_dirs)     do
    described_class::DIRS.map do |f|
      File.expand_path File.join(application_name, f)
    end + [application_name]
  end

  before do
    rm_rf application_name
    described_class.start([application_name])
  end

  describe '#execute' do

    it 'creates the application folder structure' do

      RCoreMidi::CLI::DIRS.each do |dir|
        Dir.exists?(dir)
      end

      application_file = File.join('spec', application_name, described_class::APPLICATION)
      expect(File.exists?(application_file)).to be true
      expect(File.read(application_file)).to eq("require 'rcoremidi'\n\nclass DummyApp < RCoreMidi::Application\n\nend\n")
    end
  end

end
