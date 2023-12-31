require 'rcoremidi/commands/application_helper'

module RCoreMidi
  module Commands
    class Connections < Thor::Group
      include ApplicationHelper
      TABLE_HEADER = ['DEVICE NAME', 'PORT', 'MODEL', 'UID', 'STATUS', 'TRANSMITS MTC', 'RECEIVES MTC'].freeze

      def display_available_connections
        midi_ins  = [TABLE_HEADER]
        midi_outs = [TABLE_HEADER]
        Device.all.each do |device|
          if device.entities_with_midi_in.any?
            device.entities_with_midi_in.each do |entity|
              entity.sources.each do |source|
                midi_ins << [device.name, entity.name, device.model, source.uid, device.offline ? 'offline' : 'online',
                             device.transmits_mtc, device.receives_mtc]
              end
            end
          end

          next unless device.entities_with_midi_out.any?

          device.entities_with_midi_out.each do |entity|
            entity.destinations.each do |destination|
              midi_outs << [device.name, entity.name, device.model, destination.uid,
                            device.offline ? 'offline' : 'online']
            end
          end
        end

        say('Available MIDI Inputs:', Thor::Shell::Color::GREEN)
        print_table midi_ins
        say("\n")
        say('Available MIDI Outputs:', Thor::Shell::Color::GREEN)
        print_table midi_outs
        say("\n")
      end
    end
  end
end
