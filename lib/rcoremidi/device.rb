module RCoreMidi
  class Device

    def entities_with_midi_in
      entities.select(&:midi_in?)
    end

    def entities_with_midi_out
      entities.select(&:midi_out?)
    end

    def as_yaml
      {
        'name'         => self.name,
        'manufacturer' => self.manufacturer,
        'entities'     => entities.map(&:as_yaml)
      }
    end
  end
end
