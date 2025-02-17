# frozen_string_literal: true

require_relative 'spec_helper'

module BinStruct
  RSpec.describe String do
    describe '#initialize' do
      it 'accepts a option hash' do
        expect { String.new(length_from: nil) }.to_not raise_error
      end

      it 'accepts a value' do
        s = String.new(value: 'test')
        expect(s.string).to eq('test')
      end
    end

    describe '#initialize_copy' do
      it 'duplicates internal string' do
        s1 = String.new.read('qwerty')
        s2 = s1.dup
        s2 << 'uiop'
        expect(s1.to_s).to_not eq(s2.to_s)
      end
    end

    describe '#<<' do
      it 'appends string to String' do
        s = String.new.read('qwerty')
        s << 'uiop'
        expect(s.string).to eq('qwertyuiop')
      end
    end

    describe '#read' do
      it 'reads all given string when no length_from option was given' do
        str = String.new
        read_str = (0..15).to_a.pack('C*')
        str.read read_str
        expect(str.sz).to eq(16)
        expect(str).to eq(read_str)
      end

      it 'reads only start of given string when length_from option was given' do
        len = Int8.new(value: 6)
        str = String.new(length_from: len)
        read_str = (0..15).to_a.pack('C*')
        str.read read_str
        expect(str.sz).to eq(6)
        expect(str).to eq(read_str[0..5])

        len.value = 12
        str.read read_str
        expect(str.sz).to eq(12)
        expect(str).to eq(read_str[0..11])
      end
    end
    context "with static length" do
      let(:s) { String.new(static_length: 10) }

      it 'always has the same size' do
        expect(s.sz).to eq(10)
        s.read("abcd")
        expect(s.sz).to eq(10)
      end

      it 'reads at most static length data' do
        s.read('abcdefghijklmnopqrstuvwxyz'.b)
        expect(s.to_s).to eq('abcdefghij'.b)
      end

      it 'serailizes an empty string with all zeros' do
        expect(s.to_s).to eq((([0] * 10).pack('C*')))
      end


      it 'serailizes with limit to static length' do
        s.string[0, 1] = '12345678910111213'
        expect(s.to_s).to eq('1234567891'.b)
      end
    end
  end
end
