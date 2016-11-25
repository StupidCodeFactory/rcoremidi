module RCoreMidi
  module Commands
    class Status < Thor::Group

      def application
        @application || RCoreMidi::Application.new(Dir.pwd)
      end

      def log_application_status
        application.log_status
      end
    end
  end
end
