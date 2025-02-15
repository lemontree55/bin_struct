# frozen_string_literal: true

require_relative 'spec_helper'

module BSStructSpec
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
    define_bit_attr :u32, has_optional: 1, others: 31
    define_attr :optional, BinStruct::Int32, optional: lambda(&:has_optional?)
  end

  class FInspectTest < BinStruct::Struct
    define_attr :is, BinStruct::IntString, default: 'test'
    define_attr :int, BinStruct::Int8
    define_bit_attr :int2, one: 4, two: 2, three: 1, four: 1, five: 8
    define_attr :enum, BinStruct::Int32Enum, enum: {'no' => 0, 'yes' => 1 }
  end

  class DeleteTest < BinStruct::Struct
    define_attr :to_be_deleted, BinStruct::Int16
  end

  class ReadInitializer < BinStruct::Struct
    define_attr :ary, BinStruct::ArrayOfInt8
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
end

module BinStruct
  RSpec.describe Struct do

    after(:each) do
      BSStructSpec::STest.class_eval do
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
        expect(BSStructSpec::STest.new.attributes).to be_empty
        BSStructSpec::STest.class_eval { define_attr :f1, Int8 }
        expect(BSStructSpec::STest.new.attributes).to eq([:f1])
      end

      it 'adds a attribute with specified type' do
        BSStructSpec::STest.class_eval { define_attr :f1, Int8 }
        ft = BSStructSpec::STest.new
        expect(ft[:f1]).to be_a(Int8)
        expect(ft.f1).to be_a(Integer)
        ft.f1 = 123
        expect(ft[:f1].value).to eq(123)

        BSStructSpec::STest.class_eval { define_attr :f2, Int32 }
        ft = BSStructSpec::STest.new
        expect(ft[:f2]).to be_a(Int32)
        expect(ft.f2).to be_a(Integer)
        ft.f2 = 1234
        expect(ft[:f2].value).to eq(1234)

        BSStructSpec::STest.class_eval { define_attr :f3, String }
        ft = BSStructSpec::STest.new
        expect(ft[:f3]).to be_a(String)
        expect(ft.f3).to be_a(::String)
        ft.f3 = 'abcd'
        expect(ft[:f3]).to eq('abcd')
      end

      it 'adds a attribute with default value' do
        BSStructSpec::STest.class_eval { define_attr :f1, Int8, default: 255 }
        expect(BSStructSpec::STest.new.f1).to eq(255)

        BSStructSpec::STest.class_eval { define_attr :f2, Int16, default: ->(_h) { rand(1...9) } }
        expect(BSStructSpec::STest.new.f2).to be > 0
        expect(BSStructSpec::STest.new.f2).to be < 9
      end

      it 'adds a attribute with given builder' do
        BSStructSpec::STest.class_eval { define_attr :f1, Int8, builder: ->(_x, _t) { Int16.new } }
        expect(BSStructSpec::STest.new[:f1]).to be_a(Int16)
      end
    end

    describe '.define_attr_before' do
      before(:each) do
        BSStructSpec::STest.class_eval do
          define_attr :f1, Int8
          define_attr :f2, Int8
        end
      end

      it 'adds a attribute before another one' do
        BSStructSpec::STest.class_eval { define_attr_before :f1, :f3, Int8 }
        expect(BSStructSpec::STest.new.attributes).to eq(%i[f3 f1 f2])

        BSStructSpec::STest.class_eval { define_attr_before :f2, :f4, Int8 }
        expect(BSStructSpec::STest.new.attributes).to eq(%i[f3 f1 f4 f2])
      end

      it 'raises on unknown before attribute' do
        expect { BSStructSpec::STest.class_eval { define_attr_before :unk, :f3, Int8 } }
          .to raise_error(ArgumentError, 'unknown unk attribute')
      end
    end

    describe '.define_attr_after' do
      before(:each) do
        BSStructSpec::STest.class_eval do
          define_attr :f1, Int8
          define_attr :f2, Int8
        end
      end

      it 'adds a attribute after another one' do
        BSStructSpec::STest.class_eval { define_attr_after :f1, :f3, Int8 }
        expect(BSStructSpec::STest.new.attributes).to eq(%i[f1 f3 f2])

        BSStructSpec::STest.class_eval { define_attr_after :f2, :f4, Int8 }
        expect(BSStructSpec::STest.new.attributes).to eq(%i[f1 f3 f2 f4])
      end

      it 'raises on unknown after attribute' do
        expect { BSStructSpec::STest.class_eval { define_attr_after :unk, :f3, Int8 } }
          .to raise_error(ArgumentError, 'unknown unk attribute')
      end
    end

    describe '.update_attr' do
      before(:each) do
        BSStructSpec::STest.class_eval do
          define_attr :f1, Int8
          define_attr :f2, Int8
        end
      end

      it 'updates default value of given attribute' do
        BSStructSpec::STest.update_attr :f1, default: 45
        expect(BSStructSpec::STest.new.f1).to eq(45)
      end

      it 'updates builder of given attribute' do
        BSStructSpec::STest.update_attr :f2, builder: ->(_h, _t) { Int16.new }
        expect(BSStructSpec::STest.new[:f2]).to be_a(Int16)
      end

      it 'updates optional attribute of given attribute' do
        BSStructSpec::STest.update_attr :f2, optional: ->(h) { h.f1 > 0x7f }
        expect(BSStructSpec::STest.new(f1: 0x45).present?(:f2)).to be(false)
        expect(BSStructSpec::STest.new(f1: 0xff).present?(:f2)).to be(true)
      end

      it 'updates enum attribute of given attribute' do
        BSStructSpec::STest.class_eval { define_attr :f3, Int8Enum, enum: { 'two' => 2 } }
        expect(BSStructSpec::STest.new[:f3].to_human).to eq('two')
        BSStructSpec::STest.update_attr :f3, enum: { 'one' => 1 }
        expect(BSStructSpec::STest.new[:f3].to_human).to eq('one')
      end
    end

    describe '.remove_attr' do
      it 'removes an attribute' do
        d1 = BSStructSpec::DeleteTest.new
        expect(d1.attributes).to include(:to_be_deleted)
        expect(d1).to respond_to(:to_be_deleted )
        expect(d1).to respond_to(:to_be_deleted=)

        BSStructSpec::DeleteTest.remove_attr :to_be_deleted
        d2 = BSStructSpec::DeleteTest.new
        expect(d2.attributes).to_not include(:to_be_deleted)
        expect(d2).to_not respond_to(:to_be_deleted )
        expect(d2).to_not respond_to(:to_be_deleted=)
      end

      it 'removes defined bit attributes' do
        BSStructSpec::STest.class_eval do
          define_bit_attr :u8, b0: 1, b1: 1, b2: 1, b3: 1, b4: 1, b5: 1, b6: 1, b7: 1
        end
        ft = BSStructSpec::STest.new
        expect(ft).to respond_to(:b0?)
        expect(ft).to respond_to(:b0=)
        expect(ft).to respond_to(:b7?)
        expect(ft).to respond_to(:b7=)

        BSStructSpec::STest.class_eval { remove_attr :u8 }
        expect(ft).to_not respond_to(:b0?)
        expect(ft).to_not respond_to(:b0=)
        expect(ft).to_not respond_to(:b7?)
        expect(ft).to_not respond_to(:b7=)
      end
    end

    describe '.define_bit_attr' do
      it 'adds a bit attribute' do
        BSStructSpec::STest.class_eval do
          define_bit_attr :u8, b0: 1, b1: 1, b2: 1, b3: 1, b4: 1, b5: 1, b6: 1, b7: 1
        end
        ft = BSStructSpec::STest.new
        8.times do |i|
          expect(ft).to respond_to(:"b#{i}?")
          expect(ft).to respond_to(:"b#{i}=")
        end

        expect(ft.u8).to eq(0)
        ft.u8 = 0x40
        expect(ft.b0).to be(0)
        expect(ft.b1).to be(1)
        expect(ft.b2).to be(0)
      end

      it 'adds a bit attribute with default value' do
        BSStructSpec::STest.class_eval do
          define_bit_attr :u8, default: 0x78, a: 4, b: 4
        end
        ft = BSStructSpec::STest.new
        expect(ft.u8).to eq(0x78)
        expect(ft.a).to eq(7)
        expect(ft.b).to eq(8)
      end

      it 'defines boolean methods on 1-bit attributes' do
        BSStructSpec::STest.class_eval do
          define_bit_attr :u8, b0: 1, b1: 1, b2: 6
        end

        st = BSStructSpec::STest.new
        expect(st).to respond_to(:b0?)
        expect(st).to respond_to(:b1?)
        expect(st).to_not respond_to(:b2?)

        st.u8 = 0x40
        expect(st.b0?).to be(false)
        expect(st.b1?).to be(true)
      end

      it 'accepts booelab on 1-bit setters' do
        BSStructSpec::STest.class_eval do
          define_bit_attr :u8, b0: 1, b1: 1, b2: 6
        end

        st = BSStructSpec::STest.new
        st.b0 = true
        st.b1 = false
        expect(st.u8).to eq(0x80)
      end

      it 'adds muliple-bit attributes' do
        BSStructSpec::STest.class_eval do
          define_bit_attr :u8, f1: 4, f2: 1, f3: 3
        end
        ft = BSStructSpec::STest.new
        expect(ft).to respond_to(:f1)
        expect(ft).to respond_to(:f1=)
        expect(ft).to respond_to(:f2)
        expect(ft).to respond_to(:f2?)
        expect(ft).to respond_to(:f2=)
        expect(ft).to respond_to(:f3)
        expect(ft).to respond_to(:f3=)
        ft.u8 = 0xc9
        expect(ft.f1).to eq(0xc)
        expect(ft.f2).to eq(1)
        expect(ft.f2?).to eq(true)
        expect(ft.f3).to eq(1)
        ft.f1 = 0xf
        ft.f2 = false
        ft.f3 = 7
        expect(ft.u8).to eq(0xf7)
      end
    end

    describe '.define_bit_attr_before' do
      before(:each) do
        BSStructSpec::STest.class_eval do
          define_attr :f1, Int8
          define_attr :f2, Int8
        end
      end

      it 'adds a attribute before another one' do
        BSStructSpec::STest.class_eval { define_bit_attr_before :f1, :f3, one: 1, two: 7 }
        expect(BSStructSpec::STest.new.attributes).to eq(%i[f3 f1 f2])

        BSStructSpec::STest.class_eval { define_bit_attr_before :f2, :f4, one: 8 }
        expect(BSStructSpec::STest.new.attributes).to eq(%i[f3 f1 f4 f2])
      end

      it 'raises on unknown before attribute' do
        expect { BSStructSpec::STest.class_eval { define_bit_attr_before :unk, :f3, one: 8 } }
          .to raise_error(ArgumentError, 'unknown unk attribute')
      end
    end

    describe '.define_bit_attr_after' do
      before(:each) do
        BSStructSpec::STest.class_eval do
          define_attr :f1, Int8
          define_attr :f2, Int8
        end
      end

      it 'adds a attribute after another one' do
        BSStructSpec::STest.class_eval { define_bit_attr_after :f1, :f3, one: 1, two: 7 }
        expect(BSStructSpec::STest.new.attributes).to eq(%i[f1 f3 f2])

        BSStructSpec::STest.class_eval { define_bit_attr_after :f2, :f4, one: 8 }
        expect(BSStructSpec::STest.new.attributes).to eq(%i[f1 f3 f2 f4])
      end

      it 'raises on unknown after attribute' do
        expect { BSStructSpec::STest.class_eval { define_bit_attr_before :unk, :f3, one: 8 } }
          .to raise_error(ArgumentError, 'unknown unk attribute')
      end
    end

    describe '#initialize' do
      it 'accepts a Structurable object as value for an attribute' do
        object_value = Int8.new(value: 42)
        ot = BSStructSpec::OffsetTest.new(one: object_value)
        expect(ot.one).to eq(42)
        expect(ot[:one]).to equal(object_value)
      end

      it 'accepts human-readable data' do
        ot = BSStructSpec::OffsetTest.new(one: 42)
        expect(ot.one).to eq(42)
      end

      it 'fallbacks on #read to initialize value' do
        ri = BSStructSpec::ReadInitializer.new(ary: [1, 2, 3])
        expect(ri.to_s).to eq("\x01\x02\x03".b)
      end
    end

    describe '#offset_of' do
      it 'gives offset of given attribute in structure' do

        test = BSStructSpec::OffsetTest.new
        expect(test.offset_of(:one)).to eq(0)
        expect(test.offset_of(:two)).to eq(1)
        expect(test.offset_of(:three)).to eq(3)
        expect(test.offset_of(:four)).to eq(7)
      end

      it 'gives offset of given attribute in structure with some variable attribute lengths' do
        test = BSStructSpec::OffsetTest2.new
        expect(test.offset_of(:one)).to eq(0)
        test.variable = '0123'
        expect(test.offset_of(:one)).to eq(4)
      end
    end

    describe '#bits_on' do
      before(:each) do
        BSStructSpec::STest.class_eval do
          define_bit_attr :u81, f1: 1, f2: 1, f3: 1, f4: 1, f5: 4
          define_attr :u82, Int8
        end
        @ft = BSStructSpec::STest.new
      end

      it 'returns a hash: keys are bit attributes, values are their size' do
        expect(@ft.bits_on(:u81)).to eq(%I[f1 f2 f3 f4 f5])
      end

      it 'return nil on attribute which does not define bits' do
        expect(@ft.bits_on(:u82)).to be(nil)
      end
    end

    context 'may define an optional attribute' do
      let(:f) { BSStructSpec::SOptional.new }

      it 'which is listed in optional attributes' do
        expect(f.optional?(:optional)).to be(true)
        expect(f.optional_attributes).to include(:optional)
        expect(f.optional_attributes).to_not include(:u8)
      end

      it 'which may be parsed' do
        f.read("\x80\x00\x00\x00\x01\x23\x45\x67".b)
        expect(f.has_optional?).to be(true)
        expect(f.present?(:optional)).to be(true)
        expect(f.optional).to eq(0x1234567)
      end

      it 'which may be not parsed' do
        f.read("\x00\x00\x00\x00\x01\x23\x45\x67".b)
        expect(f.has_optional?).to be(false)
        expect(f.present?(:optional)).to be(false)
        expect(f.optional).to eq(0)
      end

      it 'which may be serialized' do
        f.has_optional = true
        f.optional = 0x89abcdef
        expect(f.to_s).to eq("\x80\x00\x00\x00\x89\xab\xcd\xef".b)
      end

      it 'which may be not serialized' do
        f.has_optional = false
        f.optional = 0x89abcdef
        expect(f.to_s).to eq("\x00\x00\x00\x00".b)
      end
    end

    describe '#inspect' do
      let(:inspect_lines) { BSStructSpec::FInspectTest.new.inspect.lines }

      it 'shows Int attributes' do
        expect(inspect_lines).to include(/Int8\s+int: 0\s+\(0x00\)/)
        expect(inspect_lines).to include(/BitAttr16\s+int2: 0\s+\(0x0000\)/)
        expect(inspect_lines).to include(/one:0 two:0 three:0 four:0 five:0/)
      end

      it 'shows Enum attributes' do
        expect(inspect_lines).to include(/Int32Enum\s+enum: no\s+\(0x00000000\)/)
      end

      it 'shows IntString attributes' do
        expect(inspect_lines).to include(/IntString\s+is: test/)
      end

      it 'uses delegation' do
        lines = BSStructSpec::FInspectedTest.new.inspect.lines
        expect(lines).to include(/BinStruct::IntString\s+is: 4test/)
      end
    end

    describe '#to_h' do
      it 'generates a Hash with attributes/values as keys/values' do
        s = BSStructSpec::OffsetTest.new(one: 1, two: 2, three: 3, four: 4)
        h = s.to_h
        expect(h).to eq({ one: 1, two: 2, three: 3, four: 4 })
      end
    end

    describe '#initialize_copy' do
      it 'duplicates all attributes' do
        s1 = BSStructSpec::OffsetTest.new(one: 1, two: 2, three: 3, four: 4)
        s2 = s1.dup
        s2.three = 33
        expect(s1.to_s).to eq("\x01\x00\x02\x00\x00\x00\x03\x00\x00\x04".b)
        expect(s2.to_s).to eq("\x01\x00\x02\x00\x00\x00\x21\x00\x00\x04".b)
      end
    end

    describe '#attribute?' do
      it 'returns true if given attribute is defined' do
        s1 = BSStructSpec::OffsetTest.new
        expect(s1.attribute?(:one)).to be(true)
      end

      it 'returns false if given attribute is not defined' do
        s1 = BSStructSpec::OffsetTest.new
        expect(s1.attribute?(:twelve)).to be(false)
      end
    end
  end
end
