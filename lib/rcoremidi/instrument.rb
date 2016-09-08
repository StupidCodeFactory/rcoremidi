module RCoreMidi
  class InvalidNotName < ArgumentError; end

  class Instrument

    include RCoreMidi::Registrable

    def initialize(name, channel, &block)
      self.name    = name
      self.channel = channel
      instance_eval(&block)
    end

    def generate_bar(bar, duration_calculator)
      track.generate(bar, duration_calculator)
    end

    def play(bar, clip_name, enable_probability = false)
      track.play(bar, clip(clip_name), enable_probability)
    end

    private
    attr_accessor :name, :channel, :file
    attr_writer :tracks

    def track
      @track ||= Track.new
    end

    def clip(name)
      Clip[name]
    end

  end

end
