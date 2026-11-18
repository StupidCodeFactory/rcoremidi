require 'spec_helper'
require 'rcoremidi/cli'
require 'tmpdir'

RSpec.describe RCoreMidi::Commands::New do
  let(:application_name) { File.join(Dir.pwd, 'music', 'dummy_app') }
  let(:application_file) { File.join(application_name, 'config', described_class::APPLICATION) }

  around do |example|
    Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
  end

  before do
    expect { described_class.start([application_name]) }.to output.to_stdout
  end

  it 'creates the application folder structure' do
    RCoreMidi::CLI::DIRS.each do |dir|
      expect(File).to be_directory(File.join(application_name, dir))
    end
  end

  it 'writes the application class named after the folder' do
    expect(File.read(application_file)).to include('class DummyApp < RCoreMidi::Application')
  end

  it 'registers the starter clip and instrument under the folder name' do
    expect(File.read(File.join(application_name, 'clips', 'clip.rb')))
      .to include('RCoreMidi::Clip.register :dummy_app do')
    expect(File.read(File.join(application_name, 'instruments', 'instrument.rb')))
      .to include('RCoreMidi::Instrument.register :dummy_app, 0 do')
  end

  it 'generates Ruby that parses' do
    Dir[File.join(application_name, '**', '*.rb')].each do |file|
      expect { RubyVM::InstructionSequence.compile_file(file) }.not_to raise_error
    end
  end

  it 'writes a Gemfile pointing at this rcoremidi and musicalism' do
    expect(File.read(File.join(application_name, 'Gemfile'))).to include(
      "gem 'rcoremidi', path: '#{File.expand_path('../../..', __dir__)}'",
      "gem 'musicalism', path: '#{Gem.loaded_specs.fetch('musicalism').full_gem_path}'"
    )
  end
end
