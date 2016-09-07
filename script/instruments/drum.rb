play 'C4',  [
  1.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.8, 0.0,
  0.0, 0.0, 0.0, 0,
  0.0, 0.0, 0.0, 0
],
  probability_generator: -> { SecureRandom.random_number }


play 'D4',  [
  0.0, 0.0, 0.0, 0.0,
  1.0, 0.0, 0.2, 0.0,
  0.0, 0.0, 0.2, 0.4,
  1.0, 0.0, 0.0, 0.0
],
  probability_generator: -> { SecureRandom.random_number }

# play 'E4',  [
#   0.0, 0.0, 0.0, 0.1,
#   1.4, 0.2, 0.0, 0.0,
#   0.0, 0.0, 0.0, 0.0,
#   0.0, 0.0, 0.0, 0.0
# ]

# play 'B4',  [  0.0,  0.0,  1.0, 0.0,  0.9, 0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.1,  0.5, 0.0,  0.5, 0.1 ], probability_generator: -> { SecureRandom.random_number }
play 'F#4', [
  1.0, 0.2,  0.6, 0.2,
  0.4, 0.1,  0.0, 0.15,
  0.9, 0.1,  0.0, 0.0,
  0.4, 0.2,  0.2, 0.35
],
  probability_generator: -> { SecureRandom.random_number }

play 'G#4', [  0.0,  4.0,  0.0, 0.7 ] * 4, probability_generator: -> { SecureRandom.random_number }
play 'D5', [  0.0,  0.0,  0.0, 0.0,  0.0, 0.0,  0.2, 0.0, 0.0, 0.9, 0.9, 0.9,  0.2, 0.0,  0.0, 0.9 ], probability_generator: -> { SecureRandom.random_number }
