module RCoreMidi
  class Entity
    attr_reader :device
    def sources
      endpoints.select {|e| e.is_a? Source }
    end

    def destinations
      endpoints.select {|e| e.is_a? Destination }
    end

    def midi_in?
      sources.any?
    end

    def midi_out?
      destinations.any?
    end

    def as_yaml
      {
        'name' => self.name,
        'uid'  => self.uid,
        'sources'      => sources.map(&:as_yaml),
        'destinations' => destinations.map(&:as_yaml)
      }
    end
  end
end
