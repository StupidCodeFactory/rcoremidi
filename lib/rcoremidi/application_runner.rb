module RCoreMidi

  class ApplicationRunner

    def run()
      Process.daemon
      redirect_output
      write_pid_file(Process.pid)
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

  end

end
