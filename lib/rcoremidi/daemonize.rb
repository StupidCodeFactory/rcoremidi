# frozen_string_literal: true

module Rcoremidi
  module Daemonize # :nodoc:
    def daemonize
      exit if fork
      Process.setsid
      exit if fork
      yield
      set_process_title
      Dir.chdir '/'
    end

    def write_pid
      return if root.pid_file.exist?
      root.pid_file.expand_path.open(::File::CREAT | ::File::EXCL | ::File::WRONLY) { |f| f.write(Process.pid.to_s) }
      at_exit { destroy_pid_file }
    rescue Errno::EEXIST
      check_pid
      retry
    end

    def redirect_output
      FileUtils.touch root.log_file
      root.log_file.chmod(0o644)
      $stderr.reopen(root.log_file, 'a')
      $stdout.reopen($stderr)
      $stdout.sync = $stderr.sync = true
    end

    def set_process_title
      Process.setproctitle(format('arcx live:%d - in %s', config.bpm, root))
    end

    def check_pid
      return unless root.pid_file.exist?
      case pid_status
      when :running, :not_owned
        config.logger.info "A server is already running. Check #{root.pid_file}"
        exit(1)
      when :dead
        root.pid_file.delete
      end
    end

    def pid_status
      return :exited unless root.pid_file.exist?
      pid = root.pid_file.read.to_i
      return :dead if pid == 0
      Process.kill(0, pid) # check process status
      :running
    rescue Errno::ESRCH
      :dead
    rescue Errno::EPERM
      :not_owned
    end

    def trap_signals
      trap('QUIT', proc {
             listeners.stop
             client.dispose
             exit(0)
           })
    end

    def destroy_pid_file
      return unless root.pid_file.expand_path.exist?
      root.pid_file.expand_path.delete
    end
  end
end
