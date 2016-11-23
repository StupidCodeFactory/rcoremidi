module RCoreMidi
  module Commands

    class CreateClip < Clamp::Command

      parameter 'NAME', 'Application Name', attribute_name: :clip_name

      def execute
        puts "clip?"
      end
    end

  end
end
