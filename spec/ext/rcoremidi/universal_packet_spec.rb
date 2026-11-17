require 'spec_helper'

RSpec.describe RCoreMidi::UniversalPacket do
  describe '.words_for' do
    it 'encodes a note on as a MIDI 1.0 channel voice message' do
      expect(described_class.words_for([0x90, 60, 100])).to eq([0x20903C64])
    end

    it 'encodes a two-byte channel message' do
      expect(described_class.words_for([0xC2, 5])).to eq([0x20C20500])
    end

    it 'encodes system real-time and common messages' do
      expect(described_class.words_for([0xF8, 0xF2, 0x10, 0x02])).to eq([0x10F80000, 0x10F21002])
    end

    it 'encodes several messages in one stream' do
      expect(described_class.words_for([0x90, 60, 100, 0x80, 60, 0])).to eq([0x20903C64, 0x20803C00])
    end

    it 'encodes a short system exclusive message in one packet' do
      expect(described_class.words_for([0xF0, 1, 2, 3, 0xF7])).to eq([0x30030102, 0x03000000])
    end

    it 'splits a long system exclusive message into start and end packets' do
      expect(described_class.words_for([0xF0, 1, 2, 3, 4, 5, 6, 7, 0xF7]))
        .to eq([0x30160102, 0x03040506, 0x30310700, 0x00000000])
    end

    it 'encodes an empty system exclusive message' do
      expect(described_class.words_for([0xF0, 0xF7])).to eq([0x30000000, 0x00000000])
    end

    it 'rejects running status' do
      expect { described_class.words_for([60, 100]) }.to raise_error(ArgumentError, /status byte/)
    end

    it 'rejects an incomplete message' do
      expect { described_class.words_for([0x90, 60]) }.to raise_error(ArgumentError, /Incomplete/)
    end

    it 'rejects a data byte above 127' do
      expect { described_class.words_for([0x90, 60, 200]) }.to raise_error(ArgumentError, /data byte/)
    end

    it 'rejects an unterminated system exclusive message' do
      expect { described_class.words_for([0xF0, 1, 2]) }.to raise_error(ArgumentError, /0xF7/)
    end

    it 'rejects undefined status bytes' do
      expect { described_class.words_for([0xF4]) }.to raise_error(ArgumentError, /Unsupported/)
    end
  end
end
