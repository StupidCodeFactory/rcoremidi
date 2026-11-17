RCoreMidi::Clip.register :pads do
  follow :voyage do |key, step|
    if step.first_bar? && step.modulation
      step.modulation[1..-2].each_with_index do |chord_on_the_way, half|
        chord chord_on_the_way, 16, Array.new(16) { |sixteenth| sixteenth == half * 8 ? 1 : 0 }
      end
    else
      chord key.chord(:I), 16, [1] + [0] * 15
    end

    chord key.secondary_dominant(:V), 16, [0] * 12 + [1, 0, 0, 0] if step.farthest? && step.last_bar?
  end
end
