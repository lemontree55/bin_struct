# frozen_string_literal: true

require_relative 'spec_helper'

module BSArraySpec
    MyTLV = BinStruct::AbstractTLV.create(type_class: BinStruct::Int8)

    class GoodClass < BinStruct::Array
      set_of MyTLV
    end

    class GoodClass2 < BinStruct::Array
      def record_from_hash(obj)
        MyTLV.new(obj)
      end
    end

    class BadClass < BinStruct::Array; end


    class Subclassable < BinStruct::Struct
      define_attr :type, BinStruct::Int8

      alias old_read read

      def read(str)
        if self.instance_of?(Subclassable)
          self[:type].read(str[0, 1])
          case type
          when 5
            Subclassed.new.read(str)
          else
            self
          end
        else
          old_read(str)
        end
      end
    end

    class Subclassed < Subclassable
      def initialize(opts={})
        opts[:type] ||= 5
        super
      end
    end

    class SubclassableSetOf < BinStruct::Array
      set_of Subclassable
      private

      def real_klass(obj)
        obj.class
      end
    end
end

module BinStruct
  RSpec.describe Array do

    let(:tlv) { BSArraySpec::MyTLV.new }
    let(:int32) { Int32.new }

    describe '#initialize_copy' do
      it 'duplicates internal array' do
        g1 = BSArraySpec::GoodClass.new
        g1.push(tlv)
        g2 = g1.dup
        g2.push(tlv)
        expect(g2.size).to_not eq(g1.size)
      end
    end

    describe '#==' do
      it 'compares 2 BinStruct::Arrays by content' do
        g1 = BSArraySpec::GoodClass.new
        g1.push(tlv)
        g2 = BSArraySpec::GoodClass2.new
        g2.push(tlv)
        expect(g1).to eq(g2)
      end

      it 'compares a BinStruct::Array with an Araay by content' do
        g1 = BSArraySpec::GoodClass.new
        g1.push(tlv)
        expect(g1).to eq([tlv])
      end
    end

    describe '#clear!' do
      it 'clears content' do
        g = BSArraySpec::GoodClass.new
        g.push(tlv)
        expect { g.clear! }.to change(g, :size).from(1).to(0)
      end

      it 'resets associated counter' do
        g = BSArraySpec::GoodClass.new(counter: int32)
        g << tlv
        expect { g.clear! }.to change(int32, :to_i).from(1).to(0)

      end
    end

    describe '#push' do
      let(:g) { BSArraySpec::GoodClass.new }
      let(:g2) { BSArraySpec::GoodClass.new }
      let(:b) { BSArraySpec::BadClass.new }

      it 'accepts an object' do
        expect { g.push(tlv) }.to change(g, :size).by(1)
        expect { g2.push(tlv) }.to change(g2, :size).by(1)
        expect { b.push(tlv) }.to change(b, :size).by(1)
      end

      it 'accepts a Hash when .set_of is used' do
        expect { g << { type: 1, value: '43' } }.to change(g, :size).by(1)
        expect(g.size).to eq(1)
        expect(g.first).to be_a(BSArraySpec::MyTLV)
        expect(g.first.type).to eq(1)
        expect(g.first.value).to eq('43')
      end

      it 'accepts a Hash when #record_from_hash is redefined' do
        expect { g2 << { type: 1, value: '43' } }.to change(g2, :size).by(1)
        expect(g2.size).to eq(1)
        expect(g2.first).to be_a(BSArraySpec::MyTLV)
        expect(g2.first.type).to eq(1)
        expect(g2.first.value).to eq('43')
      end

      it 'raises when a Hash is passed and .set_of is used nor #record_from_hash is redefined' do
        expect { b << { type: 1, value: '43' } }.to raise_error(NotImplementedError)
      end

      it 'does not update counter if one was declared at initialization' do
        ary = Array.new(counter: int32)
        expect { ary.push tlv }.to_not(change(int32, :to_i))
      end
    end

    describe '#<<' do
      it 'updates counter if one was declared at initialization' do
        ary = Array.new(counter: int32)
        expect { ary << tlv }.to change(int32, :to_i).by(1)
      end
    end

    describe '#delete' do
      it 'updates counter if one was declared at initialization' do
        ary = Array.new(counter: int32)
        ary << tlv
        expect { ary.delete tlv }.to change(int32, :to_i).by(-1)
      end
    end

    describe '#delete_at' do
      it 'updates counter if one was declared at initialization' do
        ary = Array.new(counter: int32)
        3.times { ary << tlv }
        expect { ary.delete_at(1) }.to change(int32, :to_i).by(-1)
      end

      it 'returns deleted entry' do
        ary = Array.new
        3.times  { |i| ary << BSArraySpec::MyTLV.new(type: i) }
        expect(ary.delete_at(1).type).to eq(1)
      end
    end

    describe '#sz' do
      it 'returns size, as byte count, of serialized array' do
        ary = Array.new
        3.times  { |i| ary << BSArraySpec::MyTLV.new(type: i) }
        expect(ary.sz).to eq(6)
      end
    end

    describe '#to_human' do
      it 'outputs a human-readabler string of array content' do
        ary = Array.new
        3.times { |i| ary << Int32.new(value: i) }
        expect(ary.to_human).to eq('0,1,2')
      end
    end

    describe '#read' do
      it 'accepts data from a Array of Hashes' do
        ary = BSArraySpec::GoodClass.new
        ary.read([{type: 0}, {type: 1}, {type: 4}])
        expect(ary.size).to eq(3)
        expect(ary).to all(be_a(BSArraySpec::MyTLV))
        expect(ary.map(&:type)).to eq([0, 1, 4])
      end

      it 'may create subclassed objects if set_of type permits it' do
        ary = BSArraySpec::SubclassableSetOf.new
        ary.read(binary("\x01\x05"))
        expect(ary.size).to eq(2)
        expect(ary[0]).to be_a(BSArraySpec::Subclassable)
        expect(ary[1]).to be_a(BSArraySpec::Subclassed)
      end
    end
  end

  # Check at least one flavor of ArrayOfInt
  RSpec.describe ArrayOfInt16 do
    describe '#read' do
      let (:array) { ArrayOfInt16.new }

      it 'from an Array' do
        array.read([0, 1, 65535])
        expect(array.to_s).to eq(binary("\x00\x00\x00\x01\xff\xff"))
      end

      it 'from a String' do
        array.read(binary("\x00\x00\x00\x01\xff\xff"))
        expect(array[0].to_i).to eq(0)
        expect(array[1].to_i).to eq(1)
        expect(array[2].to_i).to eq(0xffff)
      end
    end
  end
end
