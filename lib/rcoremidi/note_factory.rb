module RCoreMidi
  class NoteFactory
    def initialize(mpt)
      self.mpt = mpt
    end

    def generate(note, generator, channel)
      generator.probabilities.each_with_index.select do |proba, i|
                puts generator.play?(i).to_s + " i == #{i}"
        generator.play?(i)
      end.map do |gen, i|
        [
          Note.new(note, 90, (mpt * i * 6).ceil).on(channel),
          Note.new(note, 90, ((mpt * i * 6) + 24 * mpt).ceil).off(channel)
        ]
      end.flatten
    end

    private
    attr_accessor :mpt
  end
end
