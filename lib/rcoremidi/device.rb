module RCoreMidi
  class Device
    def as_yaml
      {
        'name'         => self.name,
        'manufacturer' => self.manufacturer,
        'entities'     => entities.map(&:as_yaml)
      }
    end
  end
end
