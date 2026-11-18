RCoreMidi::Clip.register :dfam_steps do
  velocity_staircase = (0...16).map { |step| 8 + (step * 7) }
  note 'C4', 16, [1, 0] * 8, velocity: velocity_staircase
end
