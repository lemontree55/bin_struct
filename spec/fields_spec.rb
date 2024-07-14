# frozen_string_literal: true

require_relative 'spec_helper'

module BinStruct
  RSpec.describe Fields do
    class FTest < Fields; end

    after(:each) do
      FTest.class_eval do
        @ordered_fields.clear
        @field_defs.clear
        @bit_fields.clear
        %i[b0 b1 b2 b3 b4 b5 b6 b7 f1 f2 f3 f4 f5 u8 u81 u82].each do |meth|
          undef_method meth if method_defined?(meth)
          undef_method :"#{meth}=" if method_defined?(:"#{meth}=")
          undef_method :"#{meth}?" if method_defined?(:"#{meth}?")
        end
      end
    end

    describe '.define_field' do
      it 'adds a field to class' do
        expect(FTest.new.fields).to be_empty
        FTest.class_eval { define_field :f1, Int8 }
        expect(FTest.new.fields).to eq([:f1])
      end

      it 'adds a field with specified type' do
        FTest.class_eval { define_field :f1, Int8 }
        ft = FTest.new
        expect(ft[:f1]).to be_a(Int8)
        expect(ft.f1).to be_a(Integer)
        ft.f1 = 123
        expect(ft[:f1].value).to eq(123)

        FTest.class_eval { define_field :f2, Int32 }
        ft = FTest.new
        expect(ft[:f2]).to be_a(Int32)
        expect(ft.f2).to be_a(Integer)
        ft.f2 = 1234
        expect(ft[:f2].value).to eq(1234)

        FTest.class_eval { define_field :f3, String }
        ft = FTest.new
        expect(ft[:f3]).to be_a(String)
        expect(ft.f3).to be_a(::String)
        ft.f3 = 'abcd'
        expect(ft[:f3]).to eq('abcd')
      end

      it 'adds a field with default value' do
        FTest.class_eval { define_field :f1, Int8, default: 255 }
        expect(FTest.new.f1).to eq(255)

        FTest.class_eval { define_field :f2, Int16, default: ->(_h) { rand(1...9) } }
        expect(FTest.new.f2).to be > 0
        expect(FTest.new.f2).to be < 9
      end

      it 'adds a field with given builder' do
        FTest.class_eval { define_field :f1, Int8, builder: ->(_x, _t) { Int16.new } }
        expect(FTest.new[:f1]).to be_a(Int16)
      end
    end

    describe '.define_field_before' do
      before(:each) do
        FTest.class_eval do
          define_field :f1, Int8
          define_field :f2, Int8
        end
      end

      it 'adds a field before another one' do
        FTest.class_eval { define_field_before :f1, :f3, Int8 }
        expect(FTest.new.fields).to eq(%i[f3 f1 f2])

        FTest.class_eval { define_field_before :f2, :f4, Int8 }
        expect(FTest.new.fields).to eq(%i[f3 f1 f4 f2])
      end

      it 'raises on unknown before field' do
        expect { FTest.class_eval { define_field_before :unk, :f3, Int8 } }
          .to raise_error(ArgumentError, 'unknown unk field')
      end
    end

    describe '.define_field_after' do
      before(:each) do
        FTest.class_eval do
          define_field :f1, Int8
          define_field :f2, Int8
        end
      end

      it 'adds a field after another one' do
        FTest.class_eval { define_field_after :f1, :f3, Int8 }
        expect(FTest.new.fields).to eq(%i[f1 f3 f2])

        FTest.class_eval { define_field_after :f2, :f4, Int8 }
        expect(FTest.new.fields).to eq(%i[f1 f3 f2 f4])
      end

      it 'raises on unknown after field' do
        expect { FTest.class_eval { define_field_after :unk, :f3, Int8 } }
          .to raise_error(ArgumentError, 'unknown unk field')
      end
    end

    describe '.update_field' do
      before(:each) do
        FTest.class_eval do
          define_field :f1, Int8
          define_field :f2, Int8
        end
      end

      it 'updates default value of given field' do
        FTest.update_field :f1, default: 45
        expect(FTest.new.f1).to eq(45)
      end

      it 'updates builder of given field' do
        FTest.update_field :f2, builder: ->(_h, _t) { Int16.new }
        expect(FTest.new[:f2]).to be_a(Int16)
      end

      it 'updates optional attribute of given field' do
        FTest.update_field :f2, optional: ->(h) { h.f1 > 0x7f }
        expect(FTest.new(f1: 0x45).present?(:f2)).to be(false)
        expect(FTest.new(f1: 0xff).present?(:f2)).to be(true)
      end

      it 'updates enum attribute of given field' do
        FTest.class_eval { define_field :f3, Int8Enum, enum: { 'two' => 2 } }
        expect(FTest.new[:f3].to_human).to eq('two')
        FTest.update_field :f3, enum: { 'one' => 1 }
        expect(FTest.new[:f3].to_human).to eq('one')
      end
    end

    describe '.define_bit_fields_on' do
      before(:each) do
        FTest.class_eval { define_field :u8, Int8 }
      end

      it 'adds bit fields on an Int attribute' do
        FTest.class_eval do
          define_bit_fields_on :u8, :b0, :b1, :b2, :b3, :b4, :b5, :b6, :b7
        end
        ft = FTest.new
        8.times do |i|
          expect(ft).to respond_to(:"b#{i}?")
          expect(ft).to respond_to(:"b#{i}=")
        end

        expect(ft.u8).to eq(0)
        ft.u8 = 0x40
        expect(ft.b0?).to be(false)
        expect(ft.b1?).to be(true)
        expect(ft.b2?).to be(false)

        ft.b7 = true
        ft.b1 = false
        expect(ft.u8).to eq(1)
      end

      it 'adds muliple-bit fields on an Int attribute' do
        FTest.class_eval do
          define_bit_fields_on :u8, :f1, 4, :f2, :f3, 3
        end
        ft = FTest.new
        expect(ft).to respond_to(:f1)
        expect(ft).to respond_to(:f1=)
        expect(ft).to respond_to(:f2?)
        expect(ft).to respond_to(:f2=)
        expect(ft).to respond_to(:f3)
        expect(ft).to respond_to(:f3=)
        ft.u8 = 0xc9
        expect(ft.f1).to eq(0xc)
        expect(ft.f2?).to eq(true)
        expect(ft.f3).to eq(1)
        ft.f1 = 0xf
        ft.f2 = false
        ft.f3 = 7
        expect(ft.u8).to eq(0xf7)
      end

      it 'raises on unknown attribute' do
        expect { FTest.class_eval { define_bit_fields_on :unk, :bit } }
          .to raise_error(ArgumentError, /^unknown unk field/)
      end

      it 'raises on non-Int attribute' do
        FTest.class_eval { define_field :f1, BinStruct::String }
        expect { FTest.class_eval { define_bit_fields_on :f1, :bit } }
          .to raise_error(TypeError, 'f1 is not a BinStruct::Int')
      end
    end

    describe '.remove_bit_fields_on' do
      before(:each) do
        FTest.class_eval { define_field :u8, Int8 }
      end

      it 'removes defined bit fields' do
        FTest.class_eval do
          define_bit_fields_on :u8, :b0, :b1, :b2, :b3, :b4, :b5, :b6, :b7
        end
        ft = FTest.new
        expect(ft).to respond_to(:b0?)
        expect(ft).to respond_to(:b0=)
        expect(ft).to respond_to(:b7?)
        expect(ft).to respond_to(:b7=)

        FTest.class_eval { remove_bit_fields_on :u8 }
        expect(ft).to_not respond_to(:b0?)
        expect(ft).to_not respond_to(:b0=)
        expect(ft).to_not respond_to(:b7?)
        expect(ft).to_not respond_to(:b7=)
      end

      it 'does nothing on an attribute with no bit field' do
        expect { FTest.class_eval { remove_bit_fields_on :u8 } }.to_not raise_error
      end
    end

    describe '#offset_of' do
      it 'gives offset of given field in structure' do
        class OffsetTest < Fields
          define_field :one, BinStruct::Int8
          define_field :two, BinStruct::Int16
          define_field :three, BinStruct::Int32
          define_field :four, BinStruct::Int24
        end

        test = OffsetTest.new
        expect(test.offset_of(:one)).to eq(0)
        expect(test.offset_of(:two)).to eq(1)
        expect(test.offset_of(:three)).to eq(3)
        expect(test.offset_of(:four)).to eq(7)
      end

      it 'gives offset of given field in structure with some variable field lengths' do
        class OffsetTest2 < Fields
          define_field :variable, BinStruct::String
          define_field :one, BinStruct::Int8
        end

        test = OffsetTest2.new
        expect(test.offset_of(:one)).to eq(0)
        test.variable = '0123'
        expect(test.offset_of(:one)).to eq(4)
      end
    end

    describe '#bits_on' do
      before(:each) do
        FTest.class_eval do
          define_field :u81, Int8
          define_field :u82, Int8
          define_bit_fields_on :u81, :f1, :f2, :f3, :f4, :f5, 4
        end
        @ft = FTest.new
      end

      it 'returns a hash: keys are bit fields, values are their size' do
        expect(@ft.bits_on(:u81)).to eq(f1: 1, f2: 1, f3: 1, f4: 1, f5: 4)
      end

      it 'return nil on field which does not define bits' do
        expect(@ft.bits_on(:u82)).to be(nil)
      end
    end

    context 'may define an optional field' do
      class FOptional < Fields
        define_field :u8, BinStruct::Int32
        define_bit_fields_on :u8, :has_optional, :others, 31
        define_field :optional, BinStruct::Int32, optional: lambda(&:has_optional?)
      end

      let(:f) { FOptional.new }

      it 'which is listed in optional fields' do
        expect(f.optional?(:optional)).to be(true)
        expect(f.optional_fields).to include(:optional)
        expect(f.optional_fields).to_not include(:u8)
      end

      it 'which may be parsed' do
        f.read(binary("\x80\x00\x00\x00\x01\x23\x45\x67"))
        expect(f.has_optional?).to be(true)
        expect(f.present?(:optional)).to be(true)
        expect(f.optional).to eq(0x1234567)
      end

      it 'which may be not parsed' do
        f.read(binary("\x00\x00\x00\x00\x01\x23\x45\x67"))
        expect(f.has_optional?).to be(false)
        expect(f.present?(:optional)).to be(false)
        expect(f.optional).to eq(0)
      end

      it 'which may be serialized' do
        f.has_optional = true
        f.optional = 0x89abcdef
        expect(f.to_s).to eq(binary("\x80\x00\x00\x00\x89\xab\xcd\xef"))
      end

      it 'which may be not serialized' do
        f.has_optional = false
        f.optional = 0x89abcdef
        expect(f.to_s).to eq(binary("\x00\x00\x00\x00"))
      end
    end
  end
end
