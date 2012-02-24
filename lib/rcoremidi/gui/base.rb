module RCoreMidi
  module GUI
    class Base
      ACTIONS = {
        :clear => "\e[2J\e[f",
        :reset => "\n\e[\m"
      }

      def method_missing(method)
        # TODO: call super! ...damn it!
        print ACTIONS[method] if ACTIONS.has_key?(method)
      end
    end
  end
end

