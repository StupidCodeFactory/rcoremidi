module RCoreMidi

  class Live
    attr_reader :instruments

    def initialize(instruments_dir)
      self.instruments_dir        = instruments_dir
      self.instruments            = []
    end

    def instrument name, channel
      file = File.open(File.join(instruments_dir, "#{name}.rb"))
      instruments  << Instrument.new(name, channel, file)
    end

    def generate_beats(duration_calculator)
      instruments.flat_map do |instrument|
        instrument.reload.track.map do |pitch, probabilities|
          NoteFactory.new(probabilities, duration_calculator).generate(pitch).flatten
        end
      end
    end

    private
    attr_accessor :instruments_dir, :instruments
  end
end
