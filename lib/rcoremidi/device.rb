module RCoreMidi
  class Device
    attr_reader :model, :offline, :transmits_mtc, :receives_mtc, :uid

    def entities_with_midi_in
      entities.select(&:midi_in?)
    end

    def entities_with_midi_out
      entities.select(&:midi_out?)
    end
  end
end
