# frozen_string_literal: true

require_relative 'spec_helper'

TestEnumTLV = BinStruct::AbstractTLV.create
TestEnumTLV.define_type_enum 'one' => 1, 'two' => 2

TestNoEnumTLV = BinStruct::AbstractTLV.create(type_class: BinStruct::Int8)

module BinStruct
  RSpec.describe AbstractTLV do
    describe '.create' do
      let(:tlv_class) { AbstractTLV.create }
      it 'returns a class, subclass of BinStruct::Struct' do
        expect(tlv_class).to be_a(Class)
        expect(tlv_class).to be < BinStruct::Struct
      end

      it 'returns a class, with type attribute a BinStruct::Int8Enum' do
        expect(tlv_class.attr_defs[:type][:type]).to eq(Int8Enum)
      end

      it 'returns a class, with length attribute a BinStruct::Int8' do
        expect(tlv_class.attr_defs[:length][:type]).to eq(Int8)
      end

      it 'returns a class, with value attribute a BinStruct::String' do
        expect(tlv_class.attr_defs[:value][:type]).to eq(BinStruct::String)
      end

      it 'accepts a type argument' do
        tlv_class = AbstractTLV.create(type_class: Int16)
        expect(tlv_class.attr_defs[:type][:type]).to eq(Int16)
      end

      it 'accepts a length argument' do
        tlv_class = AbstractTLV.create(length_class: Int16)
        expect(tlv_class.attr_defs[:length][:type]).to eq(Int16)
      end

      it 'accepts a value argument' do
        tlv_class = AbstractTLV.create(value_class: Int32)
        expect(tlv_class.attr_defs[:value][:type]).to eq(Int32)
      end

      it 'raises when called on a subclass' do
        expect { TestEnumTLV.create }.to raise_error(Error)
      end

      it 'accepts an aliases argument' do
        tlv_class = AbstractTLV.create(aliases: { code: :type })
        tlv = tlv_class.new
        expect(tlv).to respond_to(:type)
        expect(tlv).to respond_to(:type=)
        expect(tlv).to respond_to(:code)
        expect(tlv).to respond_to(:code=)
      end
    end

    context 'use of instance of generated class' do
      let(:tlv) { AbstractTLV.create(type_class: Int16, length_class: Int16).new }

      describe '#read' do
        it 'reads a TLV from a binary string' do
          bin_str = [1, 3, 0x12345678].pack('nnN')
          tlv.read(bin_str)
          expect(tlv.type).to eq(1)
          expect(tlv.length).to eq(3)
          expect(tlv.value).to eq(binary("\x12\x34\x56"))
        end
      end

      describe '#human_type' do
        it 'returns human readable type, if type is an Enum' do
          tlv = TestEnumTLV.new(type: 'one')
          expect(tlv.type).to eq(1)
          expect(tlv.human_type).to eq('one')
        end

        it 'returns a string, if type is not an enum' do
          tlv = TestNoEnumTLV.new(type: 3)
          expect(tlv.type).to eq(3)
          expect(tlv.human_type).to eq('3')
        end
      end

      describe '#to_human' do
        it 'returns a string (type is an Enum)' do
          tlv = TestEnumTLV.new(type: 1, value: 'abcdef')
          expect(tlv.to_human).to eq('type:one,length:6,value:"abcdef"')
        end

        it 'returns a string (type is  not an Enum)' do
          tlv = TestNoEnumTLV.new
          expect(tlv.to_human).to eq('type:0,length:0,value:""')
          tlv.type = 156
          tlv.value = 'abcd'
          expect(tlv.to_human).to eq('type:156,length:4,value:"abcd"')
        end
      end

      describe '#value=' do
        it 'sets #length' do
          tlv.value = 'abcdef'
          expect(tlv.length).to eq(6)
        end

        it 'sets #length when attr_in_length contains "L"' do
          tlv = AbstractTLV.create(type_class: Int16, length_class: Int16, attr_in_length: 'TLV').new
          tlv.value = 'abcdef'
          expect(tlv.length).to eq(10)
        end
      end

      describe 'use of aliases' do
        let(:tlv_class) { AbstractTLV.create(aliases: { code: :type }) }

        it '#initialize accepts alias as argument' do
          tlv = tlv_class.new(code: 42)
          expect(tlv.type).to eq(42)
        end

        it 'accepts alias method name' do
          tlv = tlv_class.new(code: 42)
          expect(tlv.code).to eq(42)
        end

        it 'accepts alias as a write accessor' do
          tlv = tlv_class.new(type: 0)
          expect(tlv.code).to eq(0)
          expect(tlv.type).to eq(0)
          tlv.code = 54
          expect(tlv.code).to eq(54)
          expect(tlv.type).to eq(54)
        end
      end
    end

    context 'use of instance with inverted type and length' do
      let(:ltv) do
        AbstractTLV.create(type_class: Int16, length_class: Int16, attr_order: 'LTV', attr_in_length: 'LTV').new
      end

      describe '#read' do
        it 'reads a TLV from a binary string' do
          bin_str = [7, 1, 0x12345678].pack('nnN')
          ltv.read(bin_str)
          expect(ltv.length).to eq(7)
          expect(ltv.type).to eq(1)
          expect(ltv.value).to eq(binary("\x12\x34\x56"))
        end
      end

      describe '#value=' do
        it 'sets #length when attr_in_length contains "L"' do
          ltv.value = 'abcdef'
          expect(ltv.length).to eq(10)
        end
      end
    end
  end
end
