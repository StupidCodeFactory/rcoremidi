module RCoreMidi
  class Notifier

    def initialize(clip)
      self.clip = clip
      self.tracks = []
    end

    def update(event)
      tracks.each do |tracks|
        puts subscriber.notifier
      end
    end

    def add_subscriber(clip)
      tracks << subscribers
    end

    def remove_subscriber(clip)
      tracks.delete(clip)
    end

    private
    attr_accessor :clip, :tracks
  end
end
