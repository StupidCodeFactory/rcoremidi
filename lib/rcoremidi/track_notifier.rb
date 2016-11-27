module RCoreMidi
  class TrackNotifier

    def initialize(track)
      self.track = track
    end

    def update(clip)
      track.generate()
    end

    private
    attr_accessor :track
  end
end
