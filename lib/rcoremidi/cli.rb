require 'thor'
require 'rcoremidi'
require 'rcoremidi/commands/generate'
require 'ap'
require 'yaml'
require 'byebug'

module RCoreMidi
  class CLI < Thor
    include Thor::Actions

    DIRS = [
      CLIPS_DIR       = 'clips'.freeze,
      INSTRUMENTS_DIR = 'instruments'.freeze,
      CONFIG_DIR      = 'config'.freeze,
      TMP_DIR         = 'tmp'.freeze,
      LOG_DIR         = 'log'.freeze
    ]

    APPLICATION = 'application.rb'.freeze

    def self.source_root
      File.expand_path('../templates', __FILE__)
    end

    desc 'new APP_PATH', 'Create a new rcoremidi project'
    def new
      self.destination_root = "#{destination_root}/#{name}"
      set_app_const

      empty_directory destination_root

      DIRS.each do |dir|
        empty_directory dir
      end


      template "config/#{APPLICATION}"

      inside destination_root do
        run "git init"
      end

    end

    desc 'generate GENERATOR_TYPE', "Generate code: clips and instruments"
    subcommand 'generate', Commands::Generate
    private

    def app_const
      @app_name ||= File.basename(self.destination_root).split(/_|-/).map(&:capitalize).join
    end

    alias :set_app_const :app_const

    def project_application_constant

    end

  end
end
