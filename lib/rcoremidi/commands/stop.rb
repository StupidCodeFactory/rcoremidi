module RCoreMidi
  module Commands
    class Stop < Thor::Group

      def application
        @application || RCoreMidi::Application.new(Dir.pwd)
      end

      def stop
        application.stop
        exit(0)
      end
    end
  end
end
