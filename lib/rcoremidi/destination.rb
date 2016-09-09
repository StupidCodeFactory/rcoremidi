module RCoreMidi
  class Destination
    def as_yaml
      {
        'uid' => self.uid
      }
    end
  end
end
