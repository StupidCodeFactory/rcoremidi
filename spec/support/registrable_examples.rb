shared_examples_for 'registrable' do |args|

  describe '.register' do

    let(:block_definition) do
      Proc.new {}
    end

    it "registers a named clip" do
      expect {
        described_class.register(*args, &block_definition)
      }.to change {
        described_class[args.first]
      }.from(nil).to(instance_of(described_class))
    end
  end
end
