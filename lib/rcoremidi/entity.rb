module RCoreMidi
  class Entity

    def sources
      endpoints.select {|e| e.is_a? Source }
    end

    def destinations
      endpoints.select {|e| e.is_a? Destination }
    end

  end
end
