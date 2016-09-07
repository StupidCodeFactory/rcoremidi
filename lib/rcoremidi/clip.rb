module RCoreMidi

  class Clip

    @clips = {}


    class << self
      def [](clip_name)
        @clips[clip_name]
      end

      def register(name)
        @clips[name] = new
      end
    end

  end

end
