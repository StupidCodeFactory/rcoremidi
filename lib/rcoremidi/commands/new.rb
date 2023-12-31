require 'rcoremidi/commands/application_helper'

module RCoreMidi
  module Commands
    class New < Thor::Group
      include Thor::Actions
      include ApplicationHelper
      TEMPLATES_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'templates')).freeze

      APPLICATION = 'application.rb'.freeze
      CONNECTIONS = 'connections.yml'.freeze
      ARCX        = 'arcx'.freeze
      LIVE        = 'live.rb'.freeze
      CLIP        = 'clip.rb'
      INSTRUMENT  = 'instrument.rb'

      def self.source_root
        File.expand_path('templates', File.dirname(__FILE__))
      end

      argument :name, type: :string

      def create_dirs
        self.destination_root = "#{name}"
        in_root do
          RCoreMidi::CLI::DIRS.each do |dir|
            empty_directory dir
          end
        end
      end

      def create_clip
        template "clips/#{CLIP}"
      end

      def create_instrument
        template "instruments/#{INSTRUMENT}"
      end

      def create_application
        template "config/#{APPLICATION}"
      end

      def create_connections
        template "config/#{CONNECTIONS}"
      end

      def bin
        chmod 'bin', 0o755 & ~File.umask, verbose: false
      end

      def create_arcx_bin
        template "bin/#{ARCX}"
        chmod "#{destination_root}/bin/#{ARCX}", 0o755 & ~File.umask, verbose: true
      end

      def create_live
        template "#{LIVE}"
      end

      private

      attr_accessor :application_name

      def devices
        @devices ||= Device.all
      end

      def iac_driver
        devices.detect { |device| device.name == 'IAC Driver' }
      end

      def iac_driver_bus_one
        @iac_driver_bus_one ||= iac_driver.entities.detect { |entity| entity.name == 'Bus 1' }
      end

      def midi_in
        iac_driver_bus_one.endpoints.detect { |entity| entity.is_a?(Source) }
      end

      def midi_out
        iac_driver_bus_one.endpoints.detect { |entity| entity.is_a?(Destination) }
      end

      def midi_channel
        0
      end

      def app_const
        File.basename(destination_root).split(/_|-/).map(&:capitalize).join
      end

      def client_name
        'RCoreMIDI'
      end
    end
  end
end
