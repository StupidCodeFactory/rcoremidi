play 'C4',  [
  0.85, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0,
  0.1, 0.1, 1.0, 0.0,
  0.0, 0.0, 0.0, 0.15
], probability_generator: -> { SecureRandom.random_number }
# ,mutator: -> (queue) {  }

# play 'C4',  [
#   0.85, 0.0, 0.0, 0.0,
#   0.0, 0.0, 0.0, 0.0,
#   0.1, 0.1, 1.0, 0.0,
#   0.0, 0.1, 0.4, 1
# ],
  # probability_generator: -> { SecureRandom.random_number }
#   # ,mutator: -> (queue) {  }

play 'D4',  [
  0.0, 0.0, 0.0, 0.0,
  1.0, 0.0, 0.0, 0.0,
  0.0, 0.06, 0.1, 0.2,
  1.0, 0.2, 0.05, 0.1
],
  probability_generator: -> { SecureRandom.random_number }

play 'E4',  [
  0.0, 0.0, 0.0, 0.0,
  1.0, 0.0, 0.0, 0.0,
  0.0, 0.06, 0.1, 0.2,
  1.0, 0.2, 0.05, 0.1
], probability_generator: -> { SecureRandom.random_number }


play 'D#4',  [
  0.0, 0.0, 0.0, 0.0,
  0.8, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0,
  0.6, 0.0, 0.1, 0.0
]

# play 'D5',  [  0.1,  0.1,  0.1, 0.2,  0.3, 0.2,  0.1, 0.0, 0.0, 0.0, 0.0, 0.1,  0.1, 0.1,  0.1, 0.1 ], probability_generator: -> { SecureRandom.random_number }
# play 'E5',  [  0.1,  0.1,  0.1, 0.2,  0.3, 0.2,  0.1, 0.0, 0.0, 0.0, 0.0, 0.1,  0.1, 0.1,  0.1, 0.1 ], probability_generator: -> { SecureRandom.random_number }

play 'D5', [
  1.0, 0.0,  1.0, 0.0,
  1.0, 0.9,  1.0, 0.0,
  1.0, 0.2,  0.9, 0.1,
  1.0, 0.0,  1.0, 0.9
], probability_generator: -> { SecureRandom.random_number }

play 'G#4', [  0.0,  1.0,  0.2, 1 ] * 4, probability_generator: -> { SecureRandom.random_number }

play 'A#4', [
  0.2, 0.1,  0.0, 0.1,
  0.0, 0.0,  0.2, 0.0,
  0.0, 0.1,  0.1, 0.08,
  0.2, 0.3,  0.0, 0.2
], probability_generator: -> { SecureRandom.random_number }
