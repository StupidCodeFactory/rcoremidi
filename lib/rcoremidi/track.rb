module RCoreMidi

  class Track

    def generate(bar, duration_calculator)
      clip, enable_probability = clips[bar]
      return [] unless clip
      clip.call
      clip.notes.map { |notes| notes.generate(duration_calculator, enable_probability).compact }.inject(:+)
    end

    def play(bar, clip, enable_probability)
      clips[bar] = [clip, enable_probability]
    end

    private
    attr_accessor :pitch, :probabilities, :probabiltiy_generator

    def clips
      @clips ||= {}
    end

  end
end
