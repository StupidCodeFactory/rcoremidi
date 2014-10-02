module RCoreMidi
  class Client

    def setup
      connect_to RCoreMidi::ConnectionManager.ask_for_connection?
      self
    end

    def on_tick
      generate_beats
    end

    def start
      @flag = 0
      trap 'SIGINT', Proc.new {
        dispose
        puts "quiting"
        exit(0)
      }
      # generate_beats
      sleep
    end

    def live(destination, instruments_dir, &block)
      @destination = destination
      @live = Live.new(self, instruments_dir)
      @live.instance_eval(&block)
    end

    def generate_beats
      notes_to_send = []
      @live.instruments_by_channel.each do |channel, instruments|
        instruments.each do |instrument|
          notes_to_send +=  instrument.generate(NoteFactory.new(mpt))
        end
      end

      notes_to_send.flatten!
      send_packets(@destination, notes_to_send)
    end

    def mpt
      @mpt ||= (60000000000 / @bpm.to_f) / 24.0
    end
  end
end
