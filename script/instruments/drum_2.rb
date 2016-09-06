class RythmSequence

  def initialize(pitch, probabilities, probability_generator, mutator = nil)
    self.pitch         = pitch
    self.probabilities = probabilities
    self.probabiltiy_generator = probability_generator
  end

  def generate(duration_calculator)
    probabilities.map.with_index do |probability, i|

      next unless probabiltiy_generator.play?(probability)

      Note.new(pitch, *duration_calculator.timestamps_for(i))
    end
  end

  private
  attr_accessor :pitch, :probabilities, :probabiltiy_generator

end

class MidiTrack

  def play

    note 'C4',  [
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

    note 'D4',  [
      0.0, 0.0, 0.0, 0.0,
      1.0, 0.0, 0.0, 0.0,
      0.0, 0.06, 0.1, 0.2,
      1.0, 0.2, 0.05, 0.1
    ],
      probability_generator: -> { SecureRandom.random_number }

    note 'E4',  [
      0.0, 0.0, 0.0, 0.0,
      1.0, 0.0, 0.0, 0.0,
      0.0, 0.06, 0.1, 0.2,
      1.0, 0.2, 0.05, 0.1
    ], probability_generator: -> { SecureRandom.random_number }


    note 'D#4',  [
      0.0, 0.0, 0.0, 0.0,
      0.8, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.6, 0.0, 0.1, 0.0
    ]

    # play 'D5',  [  0.1,  0.1,  0.1, 0.2,  0.3, 0.2,  0.1, 0.0, 0.0, 0.0, 0.0, 0.1,  0.1, 0.1,  0.1, 0.1 ], probability_generator: -> { SecureRandom.random_number }
    # play 'E5',  [  0.1,  0.1,  0.1, 0.2,  0.3, 0.2,  0.1, 0.0, 0.0, 0.0, 0.0, 0.1,  0.1, 0.1,  0.1, 0.1 ], probability_generator: -> { SecureRandom.random_number }

    note 'D5', [
      1.0, 0.0,  1.0, 0.0,
      1.0, 0.9,  1.0, 0.0,
      1.0, 0.2,  0.9, 0.1,
      1.0, 0.0,  1.0, 0.9
    ], probability_generator: -> { SecureRandom.random_number }

    note 'G#4', [  0.0,  1.0,  0.2, 1 ] * 4, probability_generator: -> { SecureRandom.random_number }

    note 'A#4', [
      0.2, 0.1,  0.0, 0.1,
      0.0, 0.0,  0.2, 0.0,
      0.0, 0.1,  0.1, 0.08,
      0.2, 0.3,  0.0, 0.2
    ], probability_generator: -> { SecureRandom.random_number }

  end

  private

  def note(pitch, probabilities, probability_generator: nil, mutator: nil)
    notes << RythmSequence.new(pitch, probabilities, ProbabilityGenerator.new(&probability_generator), mutator)
  end

  def notes
    @notes ||= []
  end
end
