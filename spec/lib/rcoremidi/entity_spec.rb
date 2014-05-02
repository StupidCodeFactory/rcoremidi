require 'spec_helper'
module RCoreMidi
  describe Entity do
    let(:entity) { Device.all.first.entities.first}

    it 'returns sources' do
      expect(entity.sources.first).to be_a(Source)
    end

    it 'returns sources' do
      expect(entity.destinations.first).to be_a(Destination)
    end

  end
end
