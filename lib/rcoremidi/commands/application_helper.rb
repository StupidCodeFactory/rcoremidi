module RCoreMidi
  module Commands
    module ApplicationHelper
      def application
        @application ||= Kernel.const_get(File.basename(Dir.pwd).split(/_|-/).compact.map(&:capitalize).join).new
      end
    end
  end
end
