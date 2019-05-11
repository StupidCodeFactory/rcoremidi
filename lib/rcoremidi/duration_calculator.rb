module RCoreMidi
  class DurationCalculator

    # 960 ppqn is logic pro's default
    def initialize(bpm, ppqn = 96)
      self.bpm  = bpm
      self.ppqn = ppqn
      compute_ppqn_delta_time
    end

    # quarter note    = 24  (in logic pro)
    # eigthth note    = 480 ticks
    # seixteenth note = 240 ticks
    def timestamps_for(note_index, resolution = 16)
      # A probabilities array of length 16 means
      # our current resolution is an 16th note

      # on = (mpt * 6 * note_index).round
      on = 0
      [on, (on + default_note_off_offset).round]
    end

    private
    attr_accessor :bpm, :mpt, :ppqn

    def compute_ppqn_delta_time
      @mpt ||= (60_000_000_000 / bpm.to_f) / 24.to_f
    end

    # default note offset is a seixteenth
    def default_note_off_offset
      6 * mpt
    end

  end
end
