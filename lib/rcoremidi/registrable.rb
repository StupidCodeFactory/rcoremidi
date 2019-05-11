module RCoreMidi
  module Registrable

    def self.included(klass)

      klass.instance_variable_set(:@registry, {})

      klass.define_singleton_method :all do |&block|
        @registry.values
      end

      klass.define_singleton_method :[] do |key|
        klass.instance_variable_get(:@registry)[key]
      end

      klass.define_singleton_method :register do |*args, &block|
        klass.instance_variable_get(:@registry)[args.first] ||= new(*args, &block)
        klass.instance_variable_get(:@registry)[args.first].load(&block)
      end

    end

    def load
      RCoreMidi::Application.config.logger.warn("Default Registrable method called. #{self.class} does implement #load")
    end
  end
end
