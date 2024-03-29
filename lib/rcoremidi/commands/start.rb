require 'debug'
module RCoreMidi
  module Commands
    class Start < Thor::Group
      include ApplicationHelper

      class_option :daemon, type: :boolean, default: false, aliases: %w[-d], banner: 'Start process in the background'
      def start
        application.run(options[:daemon])
        exit(0)
      end
    end
  end
end
