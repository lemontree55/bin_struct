# frozen_string_literal: true

require_relative 'spec_helper'

module BinStruct
  RSpec.describe CString do
    describe '#initialize' do
      it 'build a CString with default value' do
        cs = CString.new
        expect(cs).to eq('')
        expect(cs.sz).to eq(1)
      end

      it 'accepts a value' do
        cs = CString.new(value: 'test')
        expect(cs.string).to eq('test')
      end

      it 'accepts a static_length option' do
        cs = CString.new(static_length: 8)
        expect(cs.sz).to eq(8)
        expect(cs).to eq('')
      end
    end

    describe '#read' do
      it 'reads a CString' do
        cs = CString.new
        cs.read "abcd\x00".b
        expect(cs.sz).to eq(5)
        expect(cs.length).to eq(4)
        expect(cs).to eq('abcd')
      end

      it 'reads a CString with static length' do
        cs = CString.new(static_length: 8)
        cs.read "abcd\x00\x00\x00\x00".b
        expect(cs.sz).to eq(8)
        expect(cs.length).to eq(4)
        expect(cs).to eq('abcd')
      end
    end

    describe '#to_s' do
      it 'generates a null-terminated string' do
        cs = CString.new
        cs.read 'This is a String'
        expect(cs.to_s).to eq("This is a String\x00".b)
        expect(cs.length).to eq(16)
        expect(cs.sz).to eq(17)
      end

      it 'gets binary form for CString with previously forced length' do
        cs = CString.new(static_length: 20)
        cs.read 'This is a String'
        expect(cs.to_s).to eq("This is a String\x00\x00\x00\x00".b)
        expect(cs.length).to eq(16)
        expect(cs.sz).to eq(20)

        cs.read 'This is a too too long string'
        expect(cs.length).to eq(20)
        expect(cs).to eq('This is a too too lo')
        expect(cs.sz).to eq(20)
        expect(cs.to_s).to eq("This is a too too l\x00".b)
      end
    end
  end

  RSpec.describe '#<<' do
    let(:cs) { CString.new }
    it 'accepts a string' do
      cs.read "abcd\x00"
      cs << 'efgh'
      expect(cs.to_human).to eq('abcdefgh')
    end

    it 'accepts another CString' do
      cs.read "abcd\x00"
      cs2 = CString.new
      cs2.read "efgh\x00"
      cs << cs2
      expect(cs.to_human).to eq('abcdefgh')
    end

    it 'returns itself' do
      cs.read "abcd\x00"
      cs2 = cs << 'efgh'
      expect(cs2.to_human).to eq('abcdefgh')
      expect(cs2.object_id).to eq(cs.object_id)
    end
  end
end
