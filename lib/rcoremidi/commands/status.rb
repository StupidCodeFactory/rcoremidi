module RCoreMidi
  module Commands
    class Status < Thor::Group

      def application
        @application || RCoreMidi::Application.new(Dir.pwd)
      end

      def log_application_status
        application.log_status
        exit(0)
      end
    end
  end
end
