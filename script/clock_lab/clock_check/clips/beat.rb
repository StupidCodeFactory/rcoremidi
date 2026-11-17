RCoreMidi::Clip.register :beat do
  note 'C#2', 16, [1, 0, 0, 0] * 4
  note 'D2', 16, [1] + ([0] * 15)
end
