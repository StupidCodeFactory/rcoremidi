module RCoreMidi
  module Commands
    class Stop < Thor::Group

      def application
        @application || RCoreMidi::Application.new(Dir.pwd)
      end

      def stop
        application.stop
      end
    end
  end
end
