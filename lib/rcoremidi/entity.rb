module RCoreMidi
  class Entity

    def sources
      endpoints.select {|e| e.is_a? Source }
    end

    def destinations
      endpoints.select {|e| e.is_a? Destination }
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
