require 'rcoremidi'
require 'rcoremidi/commands'
require 'yaml'

module RCoreMidi
  class CLI < Thor
    include Thor::Actions

    DIRS = [
      CLIPS_DIR       = 'clips'.freeze,
      INSTRUMENTS_DIR = 'instruments'.freeze,
      CONFIG_DIR      = 'config'.freeze,
      TMP_DIR         = 'tmp'.freeze,
      LOG_DIR         = 'log'.freeze,
      BIN_DIR         = 'bin'.freeze
    ]

    APPLICATION = 'application.rb'.freeze

    def self.source_root
      File.expand_path(__dir__)
    end

    desc 'generate [GENERATOR_TYPE]', 'Generate code: clips and instruments'
    register Commands::Generate, 'generate', 'generate[GENERATOR_TYPE]', 'Generate code: clips and instruments'

    desc 'new [APP_PATH]', 'Generate code: clips and instruments'
    register Commands::New, 'new', 'new[APP_PATH]', 'Generate code: clips and instruments'

    desc 'connections', 'Generate a new midi connection'
    register Commands::Connections, 'connections', 'connections', 'Prints available MIDI connections'

    register Commands::Start, 'start', 'start', 'Start Arcx live session'

    register Commands::Stop, 'stop', 'stop', 'Stop Arcx live session'
    register Commands::Status, 'status', 'status', 'Check if Arcx live session is running'

    private

    def app_const
      @app_name ||= File.basename(destination_root).split(/_|-/).map(&:capitalize).join
    end
  end
end
