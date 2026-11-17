RCoreMidi::Clip.register :drums do
  hats_by_distance = [[1, 0, 0, 0], [1, 0, 1, 0], [1, 1, 1, 0], [1, 1, 1, 1]]
  note 'C#2', 16, [1, 0, 0, 0] * 4

  follow :voyage do |_key, step|
    note 'F#2', 16, hats_by_distance[[step.distance, 3].min] * 4
    note 'C#3', 16, [1] + [0] * 15 if step.arrived? && step.first_bar? && step.modulation
    note 'D2', 16, [0] * 8 + [1, 0, 1, 0, 1, 1, 1, 1] if step.bars_until_home == 1
  end
end
