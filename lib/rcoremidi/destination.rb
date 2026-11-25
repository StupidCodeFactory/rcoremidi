module RCoreMidi
  class Destination
    attr_reader :name

    # Finds the destination called +name+ across all devices, for example a
    # port of a multi-port MIDI interface ('Port 1'). Raises ArgumentError when
    # no destination or more than one device has that name.
    def self.named(name)
      matches = Device.all.flat_map do |device|
        destinations_of(device).select { |d| d.name == name }.map { |d| [device, d] }
      end
      raise ArgumentError, "No MIDI destination named \"#{name}\"" if matches.empty?
      if matches.size > 1
        raise ArgumentError, "Several MIDI devices have a destination named \"#{name}\": " \
                             "#{matches.map { |device, _| device.name }.join(', ')}"
      end

      matches.first.last
    end

    def self.destinations_of(device)
      device.entities.flat_map(&:destinations)
    end
    private_class_method :destinations_of
  end
end
