require 'spec_helper'

module RCoreMidi
  RSpec.xdescribe 'CoreMIDI driver' do
    subject(:midi_device) { MIDIObject.find_by_unique_id(uid) }
    # before { byebug; true}
    describe MIDIObject do
      describe '.find_by_unique_id' do

        describe 'when getting a device' do
          let(:uid) { 191445378 }

          its(:class)        { should eq(RCoreMidi::Device)}
          its(:name)         { should eq('IAC Driver') }
          its(:driver)       { should eq('com.apple.AppleMIDIIACDriver') }
          its(:manufacturer) { should eq('Apple Inc.') }
          its(:uid)          { should eq(191445378) }

          describe 'with entities' do
            pending 'populates the entites' do

              expect(subject.entities.count).to eq(1)
            end
          end

        end

        describe 'when getting a source' do
          let(:uid) { -1061455043 }

          its(:class)        { should eq(RCoreMidi::Source) }
          its(:uid)          { should eq(-1061455043) }
        end

        describe 'when getting a destination' do

          let(:uid) { 1362942403 }

          its(:class)        { should eq(RCoreMidi::Destination) }
          its(:uid)          { should eq(1362942403) }
        end
      end
    end

    describe Device do
      describe '.all' do
        it 'returns devices' do
          expect(Device.all).to_not be_empty
        end
      end
    end
  end
end
