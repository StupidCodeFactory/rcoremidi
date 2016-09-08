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
      if bar.is_a? Range
        bar.each do |bar_index|
          track.play(bar_index, clip(clip_name), enable_probability)
        end
        track.reset_at = bar.max
      else
        track.play(bar, clip(clip_name), enable_probability)
      end

    end

    private
    attr_accessor :name, :channel, :file
    attr_writer :tracks

    def track
      @track ||= Track.new
    end

    def clip(name)
      raise ArgumentError.new("Clip #{name} not found.") unless c = Clip[name]
      c
    end

  end

end
