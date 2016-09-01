module RCoreMidi
  class DurationCalculator

    def initialize(bpm)
      self.bpm = bpm
      compute_mpt
    end

    def apply_duration(note, note_index)
      # 6 is because only support eigthth resolution (for now!)
      on = (self.mpt * note_index * 6).ceil
      [on, (on + default_note_off_offset).ceil]
    end

    private
    attr_accessor :bpm, :mpt

    def compute_mpt
      self.mpt ||= (60000000000 / bpm.to_f) / 24.0
    end

    # default note offset is a seixteenth
    def default_note_off_offset
      16 * mpt
    end

  end
end
