require 'spec_helper'

module RCoreMidi
  describe 'CoreMIDI driver' do
    subject(:midi_device) { MIDIObject.find_by_unique_id(uid) }

    describe MIDIObject do
      describe '.find_by_unique_id' do


        describe 'when getting a device' do
          let(:uid) { 191445378 }

          its(:class)        { should eq(RCoreMidi::Device)}
          its(:name)         { should eq('IAC Driver') }
          its(:driver)       { should eq('com.apple.AppleMIDIIACDriver') }
          its(:manufacturer) { should eq('Apple Inc.') }
          its(:uid)          { should eq(191445378) }
          its(:entities)     { should_not be_empty }
        end

        describe 'when getting an entity' do
          let(:uid) { 411021342 }

          its(:class)        { should eq(RCoreMidi::Entity) }
          its(:uid)          { should eq(411021342) }
          its(:name)         { should eq('Bus 1') }
        end

        describe 'when getting a source' do
          let(:uid) { 646417791 }

          its(:class)        { should eq(RCoreMidi::Source) }
          its(:uid)          { should eq(646417791) }
        end

        describe 'when getting a destination' do
          let(:uid) { 1912813983 }

          its(:class)        { should eq(RCoreMidi::Destination) }
          its(:uid)          { should eq(1912813983) }
        end

      end
    end

    describe RCoreMidi::Device do
      let(:uid) { 191445378 }

      it 'has entities' do
        its(:entities)
      end
    end

  end
end
