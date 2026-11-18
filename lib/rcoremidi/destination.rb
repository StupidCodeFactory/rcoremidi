module RCoreMidi
  class Destination
    attr_reader :name

    def self.named(name)
      matches = Device.all.flat_map { |device| destinations_of(device).select { |d| d.name == name }.map { |d| [device, d] } }
      raise ArgumentError, "No MIDI destination named \"#{name}\"" if matches.empty?
      raise ArgumentError, "Several MIDI devices have a destination named \"#{name}\": #{matches.map { |device, _| device.name }.join(', ')}" if matches.size > 1

      matches.first.last
    end

    def self.destinations_of(device)
      device.entities.flat_map(&:destinations)
    end
    private_class_method :destinations_of
  end
end
