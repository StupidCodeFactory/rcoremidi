module RCoreMidi

  class NoteSequenceGenerator
    def initialize(mpt, note, probabilities)
      self.mpt = mpt
      self.resolution = 6 # eighth
    end

  end

  class NoteFactory
    def initialize(mpt)
      self.mpt = mpt
      self.resolution = 6 # eighth
    end

    def generate(note, generator, channel)
      current_note                = nil
      adjust_previous_note_off_ts = false
      probability_length = generator.probabilities.length
      generator.probabilities.each_with_index.map do |probability, i|

        #   if probability.nil?
        #     adjust_previous_note_off_ts = true
        #     current_note.off_timestamp  = calculate_offsets(i+1).first if probability_length == (i + 1)
        #     next
        #   else
        on, off = calculate_ts(i)
        current_note.off_timestamp = on if current_note && adjust_previous_note_off_ts
        current_note = Note.new(note, 90, on, off, channel) if generator.play?(i)
        #   end
        # current_note
      end.compact


    end

    private
    attr_accessor :mpt, :resolution

    def calculate_ts(note_index)
      on = (mpt * note_index * 6).ceil # 6 is because only support eigthth resolution (for now!)
      [on, (on + default_note_off_offset).ceil]
    end

    def calculate_offset(note_index)

    end

    # default note offset is a seixteenth
    def default_note_off_offset
      16 * mpt
    end
  end
end
