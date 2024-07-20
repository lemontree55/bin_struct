# frozen_string_literal: true

require_relative 'spec_helper'

class STest < BinStruct::Struct; end

class OffsetTest < BinStruct::Struct
  define_attr :one, BinStruct::Int8
  define_attr :two, BinStruct::Int16
  define_attr :three, BinStruct::Int32
  define_attr :four, BinStruct::Int24
end

class OffsetTest2 < BinStruct::Struct
  define_attr :variable, BinStruct::String
  define_attr :one, BinStruct::Int8
end

class SOptional < BinStruct::Struct
  define_attr :u8, BinStruct::Int32
  define_bit_attrs_on :u8, :has_optional, :others, 31
  define_attr :optional, BinStruct::Int32, optional: lambda(&:has_optional?)
end

class FInspectTest < BinStruct::Struct
  define_attr :is, BinStruct::IntString, default: 'test'
  define_attr :int, BinStruct::Int8
  define_attr :int2, BinStruct::Int16
  define_attr :enum, BinStruct::Int32Enum, enum: {'no' => 0, 'yes' => 1 }

  define_bit_attrs_on :int2, :one, 4, :two, 2, :three, :four, :five, 8
end

class FInspectedTest < FInspectTest
  def inspect
    super do |attr|
      if attr == :is
        FMT_ATTR % [self[attr].class, attr, "#{self[attr].length}#{self[attr].string}"]
      end
    end
  end
end

module BinStruct
  RSpec.describe Struct do

    after(:each) do
      STest.class_eval do
        @ordered_attrs.clear
        @attr_defs.clear
        @bit_attrs.clear
        %i[b0 b1 b2 b3 b4 b5 b6 b7 f1 f2 f3 f4 f5 u8 u81 u82].each do |meth|
          undef_method meth if method_defined?(meth)
          undef_method :"#{meth}=" if method_defined?(:"#{meth}=")
          undef_method :"#{meth}?" if method_defined?(:"#{meth}?")
        end
      end
    end

    describe '.define_attr' do
      it 'adds a attribute to class' do
        expect(STest.new.attributes).to be_empty
        STest.class_eval { define_attr :f1, Int8 }
        expect(STest.new.attributes).to eq([:f1])
      end

      it 'adds a attribute with specified type' do
        STest.class_eval { define_attr :f1, Int8 }
        ft = STest.new
        expect(ft[:f1]).to be_a(Int8)
        expect(ft.f1).to be_a(Integer)
        ft.f1 = 123
        expect(ft[:f1].value).to eq(123)

        STest.class_eval { define_attr :f2, Int32 }
        ft = STest.new
        expect(ft[:f2]).to be_a(Int32)
        expect(ft.f2).to be_a(Integer)
        ft.f2 = 1234
        expect(ft[:f2].value).to eq(1234)

        STest.class_eval { define_attr :f3, String }
        ft = STest.new
        expect(ft[:f3]).to be_a(String)
        expect(ft.f3).to be_a(::String)
        ft.f3 = 'abcd'
        expect(ft[:f3]).to eq('abcd')
      end

      it 'adds a attribute with default value' do
        STest.class_eval { define_attr :f1, Int8, default: 255 }
        expect(STest.new.f1).to eq(255)

        STest.class_eval { define_attr :f2, Int16, default: ->(_h) { rand(1...9) } }
        expect(STest.new.f2).to be > 0
        expect(STest.new.f2).to be < 9
      end

      it 'adds a attribute with given builder' do
        STest.class_eval { define_attr :f1, Int8, builder: ->(_x, _t) { Int16.new } }
        expect(STest.new[:f1]).to be_a(Int16)
      end
    end

    describe '.define_attr_before' do
      before(:each) do
        STest.class_eval do
          define_attr :f1, Int8
          define_attr :f2, Int8
        end
      end

      it 'adds a attribute before another one' do
        STest.class_eval { define_attr_before :f1, :f3, Int8 }
        expect(STest.new.attributes).to eq(%i[f3 f1 f2])

        STest.class_eval { define_attr_before :f2, :f4, Int8 }
        expect(STest.new.attributes).to eq(%i[f3 f1 f4 f2])
      end

      it 'raises on unknown before attribute' do
        expect { STest.class_eval { define_attr_before :unk, :f3, Int8 } }
          .to raise_error(ArgumentError, 'unknown unk attribute')
      end
    end

    describe '.define_attr_after' do
      before(:each) do
        STest.class_eval do
          define_attr :f1, Int8
          define_attr :f2, Int8
        end
      end

      it 'adds a attribute after another one' do
        STest.class_eval { define_attr_after :f1, :f3, Int8 }
        expect(STest.new.attributes).to eq(%i[f1 f3 f2])

        STest.class_eval { define_attr_after :f2, :f4, Int8 }
        expect(STest.new.attributes).to eq(%i[f1 f3 f2 f4])
      end

      it 'raises on unknown after attribute' do
        expect { STest.class_eval { define_attr_after :unk, :f3, Int8 } }
          .to raise_error(ArgumentError, 'unknown unk attribute')
      end
    end

    describe '.update_attr' do
      before(:each) do
        STest.class_eval do
          define_attr :f1, Int8
          define_attr :f2, Int8
        end
      end

      it 'updates default value of given attribute' do
        STest.update_attr :f1, default: 45
        expect(STest.new.f1).to eq(45)
      end

      it 'updates builder of given attribute' do
        STest.update_attr :f2, builder: ->(_h, _t) { Int16.new }
        expect(STest.new[:f2]).to be_a(Int16)
      end

      it 'updates optional attribute of given attribute' do
        STest.update_attr :f2, optional: ->(h) { h.f1 > 0x7f }
        expect(STest.new(f1: 0x45).present?(:f2)).to be(false)
        expect(STest.new(f1: 0xff).present?(:f2)).to be(true)
      end

      it 'updates enum attribute of given attribute' do
        STest.class_eval { define_attr :f3, Int8Enum, enum: { 'two' => 2 } }
        expect(STest.new[:f3].to_human).to eq('two')
        STest.update_attr :f3, enum: { 'one' => 1 }
        expect(STest.new[:f3].to_human).to eq('one')
      end
    end

    describe '.define_bit_attrs_on' do
      before(:each) do
        STest.class_eval { define_attr :u8, Int8 }
      end

      it 'adds bit attributes on an Int attribute' do
        STest.class_eval do
          define_bit_attrs_on :u8, :b0, :b1, :b2, :b3, :b4, :b5, :b6, :b7
        end
        ft = STest.new
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

      it 'adds muliple-bit attributes on an Int attribute' do
        STest.class_eval do
          define_bit_attrs_on :u8, :f1, 4, :f2, :f3, 3
        end
        ft = STest.new
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
        expect { STest.class_eval { define_bit_attrs_on :unk, :bit } }
          .to raise_error(ArgumentError, /^unknown unk attribute/)
      end

      it 'raises on non-Int attribute' do
        STest.class_eval { define_attr :f1, BinStruct::String }
        expect { STest.class_eval { define_bit_attrs_on :f1, :bit } }
          .to raise_error(TypeError, 'f1 is not a BinStruct::Int')
      end
    end

    describe '.remove_bit_attrs_on' do
      before(:each) do
        STest.class_eval { define_attr :u8, Int8 }
      end

      it 'removes defined bit attributes' do
        STest.class_eval do
          define_bit_attrs_on :u8, :b0, :b1, :b2, :b3, :b4, :b5, :b6, :b7
        end
        ft = STest.new
        expect(ft).to respond_to(:b0?)
        expect(ft).to respond_to(:b0=)
        expect(ft).to respond_to(:b7?)
        expect(ft).to respond_to(:b7=)

        STest.class_eval { remove_bit_attrs_on :u8 }
        expect(ft).to_not respond_to(:b0?)
        expect(ft).to_not respond_to(:b0=)
        expect(ft).to_not respond_to(:b7?)
        expect(ft).to_not respond_to(:b7=)
      end

      it 'does nothing on an attribute with no bit attribute' do
        expect { STest.class_eval { remove_bit_attrs_on :u8 } }.to_not raise_error
      end
    end

    describe '#offset_of' do
      it 'gives offset of given attribute in structure' do

        test = OffsetTest.new
        expect(test.offset_of(:one)).to eq(0)
        expect(test.offset_of(:two)).to eq(1)
        expect(test.offset_of(:three)).to eq(3)
        expect(test.offset_of(:four)).to eq(7)
      end

      it 'gives offset of given attribute in structure with some variable attribute lengths' do
        test = OffsetTest2.new
        expect(test.offset_of(:one)).to eq(0)
        test.variable = '0123'
        expect(test.offset_of(:one)).to eq(4)
      end
    end

    describe '#bits_on' do
      before(:each) do
        STest.class_eval do
          define_attr :u81, Int8
          define_attr :u82, Int8
          define_bit_attrs_on :u81, :f1, :f2, :f3, :f4, :f5, 4
        end
        @ft = STest.new
      end

      it 'returns a hash: keys are bit attributes, values are their size' do
        expect(@ft.bits_on(:u81)).to eq(f1: 1, f2: 1, f3: 1, f4: 1, f5: 4)
      end

      it 'return nil on attribute which does not define bits' do
        expect(@ft.bits_on(:u82)).to be(nil)
      end
    end

    context 'may define an optional attribute' do
      let(:f) { SOptional.new }

      it 'which is listed in optional attributes' do
        expect(f.optional?(:optional)).to be(true)
        expect(f.optional_attributes).to include(:optional)
        expect(f.optional_attributes).to_not include(:u8)
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

    describe '#inspect' do
      let(:inspect_lines) { FInspectTest.new.inspect.lines }

      it 'shows Int attributes' do
        expect(inspect_lines).to include(/Int8\s+int: 0\s+\(0x00\)/)
        expect(inspect_lines).to include(/Int16\s+int2: 0\s+\(0x0000\)/)
      end

      it 'does not show bit attributes' do
        expect(inspect_lines).to_not include(/one/)
        expect(inspect_lines).to_not include(/two/)
        expect(inspect_lines).to_not include(/three/)
        expect(inspect_lines).to_not include(/four/)
        expect(inspect_lines).to_not include(/five/)
      end

      it 'shows Enum attributes' do
        expect(inspect_lines).to include(/Int32Enum\s+enum: no\s+\(0x00000000\)/)
      end

      it 'shows IntString attributes' do
        expect(inspect_lines).to include(/IntString\s+is: test/)
      end

      it 'uses delegation' do
        lines = FInspectedTest.new.inspect.lines
        expect(lines).to include(/BinStruct::IntString\s+is: 4test/)
      end
    end
  end
end
