require 'spec_helper'
require 'rcoremidi/cli'

RSpec.describe RCoreMidi::Commands::CreateClip do

  include FileUtils

  before do
    RCoreMidi::Commands::New.run('new', ['dummy'])
  end

  after do
    rm_rf 'dummy'
  end

  let(:argv) { ['drum_clip'] }

  it 'creates a clip file' do
    cd ''
    described_class.run()
    clip_file = File.File.expand_path(File.join('dummy', 'clips', 'drum_clip.rb'))
    expect(File.exists?(clip_file)).to be true
  end
end
