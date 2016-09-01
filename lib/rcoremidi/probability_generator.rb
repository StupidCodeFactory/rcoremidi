module RCoreMidi

  class ProbabilityGenerator

    def initialize(&block)
      self.generator     = block
    end

    def play?(probability)
      probability > (generator.nil? ? 0 : generator.call)
    end

    private

    attr_accessor :generator

  end
end
