module RCoreMidi
  module Commands


    class CreateInstrument < Clamp::Command

      parameter 'NAME', 'Application Name', attribute_name: :instrument_name

      def execute
        puts "instrument?"
      end
    end

  end
end
