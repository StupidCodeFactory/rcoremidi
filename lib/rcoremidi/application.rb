require 'yaml'
require 'rcoremidi/app_pathname'
require 'rcoremidi/client'

module RCoreMidi

  class Configuration

    attr_accessor :bpm

    def initialize
      self.bpm = 120
    end
  end

  class Application
    attr_reader :root, :connections

    def self.config
      @@config ||= Configuration.new
    end

    def initialize(app_path)
      self.root = AppPathname.new(app_path)
      raise "Could not find application root" unless root.valid?
    end

    def run
      load_connections!
      load_clips!
      load_instruments!

      client.midi_in = midi_in
      client.midi_out = midi_out
      client.create_live(config.bpm)

      trap 'SIGINT', Proc.new {
        client.dispose
        puts "quiting"
        exit(0)
      }
      sleep
    end

    def config
      self.class.config
    end

    private
    attr_writer :root, :connections

    def client
      @client ||= RCoreMidi::Client.new(connection.first)
    end

    def midi_in
      @midi_in ||= MIDIObject.find_by_unique_id(connection.last['midi_in'])
    end

    def midi_out
      @midi_out ||= MIDIObject.find_by_unique_id(connection.last['midi_out'])
    end

    def connection
      connections.first
    end

    def load_connections!
      self.connections = YAML.load(File.read(root.connections_file))
    end

    def load_clips!
      Dir["#{root.clips_dir}/**/*.rb"].each do |app_pathname|
        load app_pathname
      end
    end

    def load_instruments!
      Dir["#{root.instruments_dir}/**/*.rb"].each do |app_pathname|
        load app_pathname
      end
    end
  end
end
