require 'spec_helper'

RSpec.describe RCoreMidi::Clip do
  describe '.register' do
    it "registers a named clip" do
      expect { described_class.register :drum }.to change { described_class[:drum] }.from(nil).to(instance_of(described_class))
    end
  end
end
