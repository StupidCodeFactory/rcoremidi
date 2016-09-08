module RCoreMidi

  class Track
    attr_accessor :reset_at
    def initialize
      self.reset_at = 0
    end

    def generate(bar, duration_calculator)
      if bar == reset_at
        return @clips = {} && []
      end

      clip, enable_probability = clips[bar]

      return [] unless clip

      clip.rythm_sequences.map { |rythm_sequence| rythm_sequence.generate(duration_calculator, enable_probability).compact }.inject(:+)
    end

    def play(bar, clip, enable_probability)
      clips[bar] = [clip, enable_probability]
    end

    private

    def clips
      @clips ||= {}
    end

  end
end
