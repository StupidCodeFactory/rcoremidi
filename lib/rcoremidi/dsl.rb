module RCoreMidi
  module DSL

    def live(client, &block)
      @live = Live.new(client)
      block.call
    end

    def instrument name, channel, &block
      client.instruments << Instrument.new(name).instance_eval(&block)
    end

  end
end

puts "loaded dsl file"
