RCoreMidi::Clip.register :drum  do
  note 'C4',  [
    0.85, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0,
    0.1, 0.1, 1.0, 0.0,
    0.0, 0.0, 0.0, 0.15
  ]

  # note 'C4',  [
  #   0.85, 0.0, 0.0, 0.0,
  #   0.0, 0.0, 0.0, 0.0,
  #   0.1, 0.1, 1.0, 0.0,
  #   0.0, 0.1, 0.4, 1
  # ]

  note 'D4',  [
    0.0, 0.0, 0.0, 0.0,
    1.0, 0.0, 0.0, 0.0,
    0.0, 0.06, 0.1, 0.2,
    1.0, 0.2, 0.05, 0.1
  ]

  note 'E4',  [
    0.0, 0.0, 0.0, 0.0,
    1.0, 0.0, 0.0, 0.0,
    0.0, 0.06, 0.1, 0.2,
    1.0, 0.2, 0.05, 0.1
  ]


  note 'D#4',  [
    0.0, 0.0, 0.0, 0.0,
    0.8, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0,
    0.6, 0.0, 0.1, 0.0
  ]

  # note 'D5',  [  0.1,  0.1,  0.1, 0.2,  0.3, 0.2,  0.1, 0.0, 0.0, 0.0, 0.0, 0.1,  0.1, 0.1,  0.1, 0.1 ], probability_generator: -> { SecureRandom.random_number }
  # note 'E5',  [  0.1,  0.1,  0.1, 0.2,  0.3, 0.2,  0.1, 0.0, 0.0, 0.0, 0.0, 0.1,  0.1, 0.1,  0.1, 0.1 ], probability_generator: -> { SecureRandom.random_number }

  note 'D5', [
    1.0, 0.0,  1.0, 0.0,
    1.0, 0.9,  1.0, 0.0,
    1.0, 0.2,  0.9, 0.1,
    1.0, 0.0,  1.0, 0.9
  ]

  note 'G#4', [  0.0,  1.0,  0.2, 1 ] * 4

  note 'A#4', [
    0.2, 0.1,  0.0, 0.1,
    0.0, 0.0,  0.2, 0.0,
    0.0, 0.1,  0.1, 0.08,
    0.2, 0.3,  0.0, 0.2
  ]
end
