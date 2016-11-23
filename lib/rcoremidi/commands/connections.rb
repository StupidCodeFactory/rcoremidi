module RCoreMidi
  module Commands
    class Connections < Thor::Group
      TABLE_HEADER = ['DEVICE NAME', 'PORT', 'MANUFACTURER', 'UID'].freeze

      def application
        @application || RCoreMidi::Application.new(::APP_PATH)
      end

      def display_available_connections
        midi_ins  = [TABLE_HEADER]
        midi_outs = [TABLE_HEADER]

        Device.all.each do |device|

          if device.entities_with_midi_in.any?
            device.entities_with_midi_in.each do |entity|
              entity.sources.each do |source|
                midi_ins << [device.name, entity.name, device.manufacturer, source.uid]
              end
            end
          end

          if device.entities_with_midi_out.any?
            device.entities_with_midi_out.each do |entity|
              entity.destinations.each do |destination|
                midi_outs << [device.name, entity.name, device.manufacturer, destination.uid]
              end
            end
          end
        end

        say("Available MIDI Inputs:", Thor::Shell::Color::GREEN)
        print_table midi_ins
        say("\n")
        say("Available MIDI Inputs:", Thor::Shell::Color::GREEN)
        print_table midi_outs
        say("\n")
      end

    end
  end
end
