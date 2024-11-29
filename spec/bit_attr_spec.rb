# frozen_string_literal: true

require_relative 'spec_helper'

module BinStruct
  RSpec.describe BitAttr do
    describe '.create' do
      it 'creates a new BitAttr subclass' do
        ba = BitAttr.create(width:8, l: 4, r: 4)
        expect(ba).to be_a(Class)
        expect(ba).to be < BitAttr
      end

      it 'returns the same subclass from same parameters' do
        ba1 = BitAttr.create(width: 8, l:4, r:4)
        ba2 = BitAttr.create(width: 8, l:4, r:4)
        expect(ba1.object_id).to eq(ba2.object_id)
      end

      it 'defines one getter method per field' do
        ba = BitAttr.create(width: 8, l: 7, r: 1).new
        expect(ba.methods).to include(:l, :r)
      end

      it 'defines one setter method per field' do
        ba = BitAttr.create(width: 8, l: 7, r: 1).new
        expect(ba.methods).to include(:l=, :r=)
      end

      it 'defines one query method per 1-bit field' do
        ba = BitAttr.create(width: 8, l: 7, r: 1).new
        expect(ba.methods).to include(:r?)
        expect(ba.methods).to_not include(:l?)
      end

      it 'accepts a width of 8, 16, 24, 32 or 64' do
        [8, 16, 24, 32, 64].each do |width|
          expect { BitAttr.create(width: width, l: width/2, r: width/2) }.to_not raise_error
        end
      end

      it 'raises for width not equal to 8, 16, 24, 32 or 64' do
        [0, 1, 2, 7, 9, 15, 17, 23, 25, 31, 33, 63, 65, 1_000].each do |width|
          expect { BitAttr.create(width: width, l: width/2, r: width/2) }.to raise_error(ArgumentError)
        end
      end

      it 'raises if width is not equal to the sum of all field sizes' do
        expect { BitAttr.create(width: 8, l: 4, r: 3) }.to raise_error(ArgumentError)
        expect { BitAttr.create(width: 8, l: 4, r: 5) }.to raise_error(ArgumentError)
      end
    end

    describe '#initialize' do
      let(:ba_class) { BitAttr.create(width: 16, l: 8, r1:4, r2: 4) }

      it 'accepts no parameters' do
        ba = ba_class.new
        expect(ba.l).to eq(0)
        expect(ba.r1).to eq(0)
        expect(ba.r2).to eq(0)
      end

      it 'accepts initial values for fields' do
        ba = ba_class.new(l: 11, r1: 7, r2: 8)
        expect(ba.l).to eq(11)
        expect(ba.r1).to eq(7)
        expect(ba.r2).to eq(8)
      end

      it 'accepts initial values from only a subsey of fields' do
        ba = ba_class.new(l: 1_000, r2: 4)
        expect(ba.l).to eq(1_000)
        expect(ba.r1).to eq(0)
        expect(ba.r2).to eq(4)
      end
    end

    describe '#read' do
      [[8, 0x1, 0xf], [16, 0x1f, 0x1f], [24, 0x1f1, 0xf1f], [32, 0x1f1f, 0x1f1f], [64, 0x1f1f1f1f, 0x1f1f1f1f]].each do |width, left, right|
        it "reads a #{width}-bit attribute from a binary string" do
          bin_str = ([0x1f] * (width / 8)).pack('C*')
          ba = BitAttr.create(width: width, l: width/2, r: width/2).new
          ba.read(bin_str)
          expect(ba.l).to eq(left)
          expect(ba.r).to eq(right)
        end
      end
    end

    describe '#to_i' do
      it 'returns integer associated with fields' do
        ba = BitAttr.create(width: 64, a: 8, b: 16, c: 32, d: 8).new(a: 1, b: 2, c: 3, d:4)
        expect(ba.to_i).to eq(0x0100020000000304)

        ba = BitAttr.create(width: 16, a: 8, b: 4, c: 4).new(a: 1, b: 2, c: 3)
        expect(ba.to_i).to eq(0x0123)
      end
    end

    describe '#to_s' do
      [[8, 0x17, 'C'], [16, 0x1718, 'n'], [24, 0x171819, 'Cn'], [32, 0x1718191a, 'N'], [64, 0x1718191a1b1c1d1e, 'Q>']].each do |width, value, packstr|
        it "generate a binary string from a #{width}-bit attribute" do
          ba = BitAttr.create(width: width, l: width/2, r: width/2).new
          ba.from_human(value)
          bin_str = case width
                    when 24
                      [value >> 16, value & 0xffff]
                    else
                      [value]
                    end.pack(packstr)
          expect(ba.to_s).to eq(bin_str)
        end
      end
    end

    context 'with endian' do
      [:big, :little, :native].each do |endian|
        it "handles #{endian} endian attribute" do
          ba_class = BitAttr.create(width: 32, endian: endian, l: 8, r: 24)
          ba = ba_class.new(l: 0x33, r: 0xabcdef)
          packstr = +"L"
          packstr << ">" if endian == :big
          packstr << "<" if endian == :little

          expect(ba.to_i).to eq(0x33abcdef)
          expect(ba.to_s).to eq([0x33abcdef].pack(packstr))
        end
      end
    end
  end
end
