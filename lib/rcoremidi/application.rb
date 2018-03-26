# frozen_string_literal: true

require 'yaml'
require 'rcoremidi/app_pathname'
require 'rcoremidi/client'
require 'logger'
require 'listen'

module RCoreMidi
  class Configuration # :nodoc:
    attr_accessor :bpm, :logger

    def initialize
      self.bpm = 120
      self.logger ||= Logger.new(STDOUT)
    end
  end

  class Application # :nodoc:
    attr_reader :root, :connections
    def self.config
      @@config ||= Configuration.new
    end

    def initialize(app_path)
      self.root = AppPathname.new(app_path).expand_path
      raise 'Could not find application root' unless root.valid?
    end

    def run(daemon_mode = false)
      load_connections!
      load_clips!

      load_instruments!

      if daemon_mode
        Process.daemon
        Process.setproctitle(format('arcx:live %s', root))
        write_pid_file
        redirect_output

        client.midi_in = midi_in
        client.midi_out = midi_out
        client.create_live

        config.logger = Logger.new(root.log_file)

        trap 'SIGINT', proc {
          client.dispose
          puts 'quiting'
          exit(0)
        }

        wait_for_start
      else
        client.midi_in = midi_in
        client.midi_out = midi_out
        client.create_live

        config.logger = Logger.new(STDOUT)

        trap 'SIGINT', proc {
          client.dispose
          puts 'quiting'
          exit(0)
        }

        wait_for_start
      end
    end

    def stop
      if root.pid_file.exist?
        Process.kill('QUIT', Integer(root.pid_file.read))
      else
        config.logger.info('No Arcx application seems to be running')
      end
    end

    def log_status
      config.logger.info("Process is #{pid_status}")
    end

    def config
      self.class.config
    end

    private

    attr_writer :root, :connections

    def listeners
      @listeners ||= Listen.to(root.clips_dir, root.instruments_dir) do |modified, added, _removed|
        (modified + added).flat_map.each do |file|
          load file
        end
      end
    end

    def wait_for_start
      listeners.start
      config.logger.info 'Arcx live successfully started'
      sleep
    end

    def redirect_output
      FileUtils.mkdir_p root.log_file.dirname
      # FileUtils.touch root.log_file
      root.log_file.chmod(0o644)
      $stderr.reopen(root.log_file, 'a')
      $stdout.reopen($stderr)
      $stdout.sync = $stderr.sync = true
    end

    def write_pid_file
      if root.pid_file.exist?
        check_pid
      else
        root.pid_file.open(::File::CREAT | ::File::EXCL | ::File::WRONLY) do |f|
          f.write(Process.pid.to_s)
        end
        at_exit do
          root.pid_file.delete if root.pid_file.exist?
        end
      end
    end

    def check_pid
      if root.pid_file.exist?
        case pid_status
        when :running, :not_owned
          puts "An arcx lie appear to with running. Check #{root.pid_file}"
          exit(1)
        when :dead
          root.pid_file.delete
        end
      end
    end

    def pid_status
      return :exited unless root.pid_file.exist?
      pid = root.pid_file.read.to_i
      return :dead if pid == 0
      Process.kill(0, pid)
      :running
    rescue Errno::ESRCH
      :dead
    rescue Errno::EPERM
      :not_owned
    end

    def client
      @client ||= RCoreMidi::Client.new(connection.first)
    end

    def midi_in
      pp connection
      @midi_in ||= MIDIObject.find_by_unique_id(connection.last['midi_in'])
    end

    def midi_out
      @midi_out ||= MIDIObject.find_by_unique_id(connection.last['midi_out'])
    end

    def connection
      connections.first
    end

    def load_connections!
      self.connections = YAML.safe_load(root.connections_file.read)
    end

    def load_clips!
      root.clip_files.each { |clip| load clip }
    end

    def load_instruments!
      root.instrument_files.each { |instrument| load instrument }
    end
  end
end
