# frozen_string_literal: true

require_relative 'spec_helper'

module BinStruct
  RSpec.describe IntString do
    describe '#initialize' do
      it 'accepts a length_type option' do
        is = IntString.new
        expect(is.sz).to eq(1)

        is = IntString.new(length_type: Int16)
        expect(is.sz).to eq(2)
        is = IntString.new(length_type: Int32)
        expect(is.sz).to eq(4)
        is = IntString.new(length_type: Int64)
        expect(is.sz).to eq(8)
      end
    end

    describe '#read' do
      let(:is8) { IntString.new }
      let(:is32) { IntString.new(length_type: Int32) }

      it 'reads an IntString' do
        is8.read binary("\x04abcd")
        expect(is8.length).to eq(4)
        expect(is8.string).to eq('abcd')

        is32.read binary("\x00\x00\x00\x06abcdef")
        expect(is32.length).to eq(6)
        expect(is32.string).to eq('abcdef')
      end

      it 'raises on too short string for given type' do
        str = "\x01a"
        expect { is32.read str }.to raise_error(Error, /too short/)
      end
    end

    describe '#to_s' do
      let(:is8) { IntString.new }
      let(:is16) { IntString.new(length_type: Int16) }

      it 'gets binary form for IntString' do
        is8.string = 'This is a String'
        expect(is8.to_s).to eq(binary("\x10This is a String"))
        is16.string = 'This is another String'
        expect(is16.to_s).to eq(binary("\x00\x16This is another String"))
      end

      it 'gets binary form for IntString with previously forced length' do
        is8.string = 'This is a String'
        is8.length = 17
        expect(is8.to_s).to eq(binary("\x11This is a String"))
        is8.length = 10
        expect(is8.to_s).to eq(binary("\x0aThis is a String"))
      end
    end

    describe '#from_human' do
      let(:is8) { IntString.new }

      it 'computes length from data' do
        is8.from_human('test')
        expect(is8.string).to eq('test')
        expect(is8.length).to eq(4)
      end
    end

    describe '#empty?' do
      it 'returns true if length is zero' do
        expect(IntString.new.empty?).to be(true)
      end

      it 'returns false if length is not zero' do
        is = IntString.new
        is.length = 42
        expect(is.empty?).to be(false)
      end
    end
  end
end
