RCoreMidi::Clip.register :bass do
  follow :voyage do |key, step|
    tonic = key.note(1)
    note "#{tonic.pitch}#{2 + step.distance / 2}", 16, [1, 0, 0, 1] * 4

    leading_tone = key.note(7)
    note "#{leading_tone.pitch}3", 16, [0, 0, 1, 0] * 4 if step.bars_until_home&.between?(1, 2)
  end
end
