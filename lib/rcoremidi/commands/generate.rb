module RCoreMidi
  module Commands
    class Generate < Thor
      include Thor::Actions

      CLIP_TEMPLATE = 'clip.rb'
      INSTRUMENT_TEMPLATE = 'instrument.rb'

      def self.source_root
        File.expand_path('../templates', __FILE__)
      end

      desc 'clip', 'Generate boilerplate code to create a clip'
      long_desc <<-LONG_DESC
This generators assists you in creating a new clip file

RCoreMidi:Clip defines rythmic and/or melodic patterns.
They can then be loaded into one or multiple instruments
LONG_DESC

      def clip(name)
        template "#{CLI::CLIPS_DIR}/#{CLIP_TEMPLATE}", "#{CLI::CLIPS_DIR}/#{name}.rb"
      end

      desc 'instrument', 'Generate boilerplate code to create an instrument'
      method_options midi_channel: :numeric
      def instrument
        template "#{Commands::New::CLIPS_DIR}/#{CLIP_TEMPLATE}", "#{CLI::INSTRUMENT_DIR}/#{name}.rb"
      end


      private

      def name
        @name
      end

      def assign_name!(name)
        @name = name
      end
    end
  end
end
