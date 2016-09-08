module RCoreMidi
  module Registrable

    def self.included(klass)

      klass.instance_variable_set(:@registry, {})

      klass.define_singleton_method :all do |&block|
        @registry.values
      end

      klass.define_singleton_method :[] do |key|
        @registry[key]
      end

      klass.define_singleton_method :register do |*args, &block|
        @registry[args.first] = new(*args, &block)
      end

    end

  end
end
