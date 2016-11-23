module RCoreMidi
  module Commands
    class Start < Thor::Group
      def application
        @application || RCoreMidi::Application.new(Dir.pwd)
      end

      def start
        application.run
      end
    end
  end
end
