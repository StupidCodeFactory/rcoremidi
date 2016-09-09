module RCoreMidi
  class Source
    def as_yaml
      {
        'uid' => self.uid
      }
    end
  end
end
