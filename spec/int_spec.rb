# frozen_string_literal: true

require_relative 'spec_helper'

module BinStruct
  RSpec.describe Int do
    describe '#initialize' do
      it 'generates an Int with default value 0' do
        expect(Int.new.to_i).to eq(0)
        expect(Int.new.value).to be_nil
      end
      it 'generates an Int with given value' do
        expect(Int.new(value: 42).value).to eq(42)
      end
      it 'accepts endianness' do
        int = nil
        expect { int = Int.new(value: 42, endian: :little) }.to_not raise_error
        expect(int.endian).to eq(:little)
      end
      it 'accepts width' do
        int = nil
        expect { int = Int.new(value: 42, endian: :little, width: 1) }.to_not raise_error
        expect(int.width).to eq(1)
      end
      it 'accepts default value' do
        int = nil
        expect { int = Int.new(value: nil, endian: :little, width: 1, default: 5) }.to_not raise_error
        expect(int.default).to eq(5)
      end
    end

    describe '#read' do
      let(:int) { Int.new }
      it 'raises on reading an Integer' do
        expect { int.read(42) }.to raise_error(Error)
      end
      it 'raises on reading a string' do
        expect { int.read("\x2a") }.to raise_error(Error)
      end
    end

    describe '#to_s' do
      it 'raises' do
        expect { Int.new.to_s }.to raise_error(StandardError, /abstract/)
      end
    end

    describe '#to_f' do
      it 'returns value as a float' do
        expect(Int.new(value: 42).to_f).to be_within(0.1).of(42.0)
      end
    end

    context 'responds to human API' do
      let(:int) { Int.new }

      it '#from_human' do
        int.from_human 42
        expect(int.value).to eq(42)
      end

      it '#to_human' do
        int.from_human 49
        expect(int.to_human).to eq(49)
      end
    end
  end

  RSpec.describe Int8 do
    let(:int) { Int8.new }

    it '#read an unsigned 8-bit integer' do
      expect(int.read("\x7f").to_i).to eq(127)
      expect(int.read("\x80").to_i).to eq(128)
    end

    it '#to_s binarize an unsigned 8-bit integer' do
      expect(int.from_human(127).to_s).to eq("\x7f".b)
      expect(int.from_human(128).to_s).to eq("\x80".b)
    end

    it '#sz returns 1' do
      expect(int.sz).to eq(1)
    end
  end

  RSpec.describe SInt8 do
    let(:int) { SInt8.new }

    it '#read a signed 8-bit integer' do
      expect(int.read("\x7f").to_i).to eq(127)
      expect(int.read("\x80").to_i).to eq(-128)
    end

    it '#to_s binarize a signed 8-bit integer' do
      expect(int.from_human(127).to_s).to eq("\x7f".b)
      expect(int.from_human(-128).to_s).to eq("\x80".b)
    end
  end

  RSpec.describe Int16 do
    let(:int) { Int16.new }

    it '#read an unsigned 16-bit big-endian integer' do
      expect(int.read("\x7f\xff").to_i).to eq(32_767)
      expect(int.read("\x80\x00").to_i).to eq(32_768)
    end

    it '#to_s binarize an unsigned 16-bit big-endian integer' do
      expect(int.from_human(32_767).to_s).to eq("\x7f\xff".b)
      expect(int.from_human(32_768).to_s).to eq("\x80\x00".b)
    end
    it '#sz returns 2' do
      expect(int.sz).to eq(2)
    end
  end

  RSpec.describe Int16le do
    let(:int) { Int16le.new }

    it '#read an unsigned 16-bit little-endian integer' do
      expect(int.read("\xff\x7f").to_i).to eq(32_767)
      expect(int.read("\x00\x80").to_i).to eq(32_768)
    end

    it '#to_s binarize an unsigned 16-bit little-endian integer' do
      expect(int.from_human(32_767).to_s).to eq("\xff\x7f".b)
      expect(int.from_human(32_768).to_s).to eq("\x00\x80".b)
    end
  end

  RSpec.describe Int16n do
    let(:int) { Int16n.new }

    it '#read an unsigned 16-bit native-endian integer' do
      expect(int.read([0x7fff].pack('S')).to_i).to eq(32_767)
      expect(int.read([0x8000].pack('S')).to_i).to eq(32_768)
    end

    it '#to_s binarize an unsigned 16-bit little-endian integer' do
      expect(int.from_human(32_767).to_s).to eq([0x7fff].pack('S'))
      expect(int.from_human(32_768).to_s).to eq([0x8000].pack('S'))
    end
  end

  RSpec.describe SInt16 do
    let(:int) { SInt16.new }

    it '#read a signed 16-bit big-endian integer' do
      expect(int.read("\x7f\xff").to_i).to eq(32_767)
      expect(int.read("\x80\x00").to_i).to eq(-32_768)
    end

    it '#to_s binarize a signed 16-bit big-endian integer' do
      expect(int.from_human(32_767).to_s).to eq("\x7f\xff".b)
      expect(int.from_human(-32_768).to_s).to eq("\x80\x00".b)
    end
  end

  RSpec.describe SInt16le do
    let(:int) { SInt16le.new }

    it '#read a signed 16-bit little-endian integer' do
      expect(int.read("\xff\x7f").to_i).to eq(32_767)
      expect(int.read("\x00\x80").to_i).to eq(-32_768)
    end

    it '#to_s binarize a signed 16-bit little-endian integer' do
      expect(int.from_human(32_767).to_s).to eq("\xff\x7f".b)
      expect(int.from_human(-32_768).to_s).to eq("\x00\x80".b)
    end
  end

  RSpec.describe SInt16n do
    let(:int) { SInt16n.new }
    it '#read a signed 16-bit native-endian integer' do
      expect(int.read([0x7fff].pack('s')).to_i).to eq(32_767)
      expect(int.read([0x8000].pack('s')).to_i).to eq(-32_768)
    end

    it '#to_s binarize a signed 16-bit native-endian integer' do
      expect(int.from_human(32_767).to_s).to eq([0x7fff].pack('s'))
      expect(int.from_human(-32_768).to_s).to eq([0x8000].pack('s'))
    end
  end

  RSpec.describe Int24 do
    let(:int) { Int24.new }
    let(:strint1) { "\x7f\xff\xff".b }
    let(:strint2) { "\x80\x00\x00".b }

    it '#read an unsigned 24-bit big-endian integer' do
      expect(int.read(strint1).to_i).to eq(0x7f_ffff)
      expect(int.read(strint2).to_i).to eq(0x80_0000)
    end
    it '#to_s binarize an unsigned 24-bit big-endian integer' do
      expect(int.from_human(0x7f_ffff).to_s).to eq(strint1)
      expect(int.from_human(0x80_0000).to_s).to eq(strint2)
    end
    it '#sz returns 3' do
      expect(int.sz).to eq(3)
    end
  end

  RSpec.describe Int24le do
    let(:int) { Int24le.new }
    let(:strint1) { "\xff\xff\x7f".b }
    let(:strint2) { "\x00\x00\x80".b }

    it '#read an unsigned 24-bit little-endian integer' do
      expect(int.read(strint1).to_i).to eq(0x7f_ffff)
      expect(int.read(strint2).to_i).to eq(0x80_0000)
    end

    it '#to_s binarize an unsigned 24-bit little-endian integer' do
      expect(int.from_human(0x7f_ffff).to_s).to eq(strint1)
      expect(int.from_human(0x80_0000).to_s).to eq(strint2)
    end
  end

  RSpec.describe Int24n do
    let(:int) { Int24n.new }
    let(:endianess) { [1].pack('S').unpack('n') == 1 ? :big : :little }
    let(:strint1) { endianess == :big ? "\x7f\xff\xff" : "\xff\xff\x7f".b }
    let(:strint2) { endianess == :big ? "\x80\x00\x00" : "\x00\x00\x80".b }
    it '#read an unsigned 24-bit little-endian integer' do
      expect(int.read(strint1).to_i).to eq(0x7f_ffff)
      expect(int.read(strint2).to_i).to eq(0x80_0000)
    end
    it '#to_s binarize an unsigned 24-bit little-endian integer' do
      expect(int.from_human(0x7f_ffff).to_s).to eq(strint1)
      expect(int.from_human(0x80_0000).to_s).to eq(strint2)
    end
  end

  RSpec.describe Int32 do
    let(:int) { Int32.new }
    it '#read an unsigned 32-bit big-endian integer' do
      expect(int.read("\x7f\xff\xff\xff").to_i).to eq(0x7fff_ffff)
      expect(int.read("\x80\x00\x00\x00").to_i).to eq(0x8000_0000)
    end
    it '#to_s binarize an unsigned 32-bit big-endian integer' do
      expect(int.from_human(0x7fff_ffff).to_s).to eq("\x7f\xff\xff\xff".b)
      expect(int.from_human(0x8000_0000).to_s).to eq("\x80\x00\x00\x00".b)
    end
    it '#sz returns 4' do
      expect(int.sz).to eq(4)
    end
  end

  RSpec.describe Int32le do
    let(:int) { Int32le.new }
    it '#read an unsigned 32-bit little-endian integer' do
      expect(int.read("\xff\xff\xff\x7f").to_i).to eq(0x7fff_ffff)
      expect(int.read("\x00\x00\x00\x80").to_i).to eq(0x8000_0000)
    end
    it '#to_s binarize an unsigned 32-bit little-endian integer' do
      expect(int.from_human(0x7fff_ffff).to_s).to eq("\xff\xff\xff\x7f".b)
      expect(int.from_human(0x8000_0000).to_s).to eq("\x00\x00\x00\x80".b)
    end
  end

  RSpec.describe Int32n do
    let(:int) { Int32n.new }
    it '#read an unsigned 32-bit little-endian integer' do
      expect(int.read([0x7fff_ffff].pack('L')).to_i).to eq(0x7fff_ffff)
      expect(int.read([0x8000_0000].pack('L')).to_i).to eq(0x8000_0000)
    end
    it '#to_s binarize an unsigned 32-bit little-endian integer' do
      expect(int.from_human(0x7fff_ffff).to_s).to eq([0x7fff_ffff].pack('L'))
      expect(int.from_human(0x8000_0000).to_s).to eq([0x8000_0000].pack('L'))
    end
  end

  RSpec.describe SInt32 do
    let(:int) { SInt32.new }
    it '#read a signed 32-bit big-endian integer' do
      expect(int.read("\x7f\xff\xff\xff").to_i).to eq(0x7fff_ffff)
      expect(int.read("\x80\x00\x00\x00").to_i).to eq(-0x8000_0000)
    end
    it '#to_s binarize a signed 32-bit big-endian integer' do
      expect(int.from_human(0x7fff_ffff).to_s).to eq("\x7f\xff\xff\xff".b)
      expect(int.from_human(-0x8000_0000).to_s).to eq("\x80\x00\x00\x00".b)
    end
  end

  RSpec.describe SInt32le do
    let(:int) { SInt32le.new }
    it '#read a signed 32-bit little-endian integer' do
      expect(int.read("\xff\xff\xff\x7f").to_i).to eq(0x7fff_ffff)
      expect(int.read("\x00\x00\x00\x80").to_i).to eq(-0x8000_0000)
    end
    it '#to_s binarize a signed 32-bit little-endian integer' do
      expect(int.from_human(0x7fff_ffff).to_s).to eq("\xff\xff\xff\x7f".b)
      expect(int.from_human(-0x8000_0000).to_s).to eq("\x00\x00\x00\x80".b)
    end
  end

  RSpec.describe SInt32n do
    let(:int) { SInt32n.new }
    it '#read a signed 32-bit little-endian integer' do
      expect(int.read([0x7fff_ffff].pack('L')).to_i).to eq(0x7fff_ffff)
      expect(int.read([0x8000_0000].pack('L')).to_i).to eq(-0x8000_0000)
    end
    it '#to_s binarize a signed 32-bit little-endian integer' do
      expect(int.from_human(0x7fff_ffff).to_s).to eq([0x7fff_ffff].pack('L'))
      expect(int.from_human(-0x8000_0000).to_s).to eq([0x8000_0000].pack('L'))
    end
  end

  INT64 = {
    big: {
      unsigned: [
        {
          int: 0x7fff_ffff_ffff_ffff,
          str: "\x7f\xff\xff\xff\xff\xff\xff\xff"
        },
        {
          int: 0x8000_0000_0000_0000,
          str: "\x80\x00\x00\x00\x00\x00\x00\x00"
        }
      ],
      signed: [
        {
          int: 0x7fff_ffff_ffff_ffff,
          str: "\x7f\xff\xff\xff\xff\xff\xff\xff"
        },
        {
          int: -0x8000_0000_0000_0000,
          str: "\x80\x00\x00\x00\x00\x00\x00\x00"
        }
      ]
    },
    little: {
      unsigned: [
        {
          int: 0x7fff_ffff_ffff_ffff,
          str: "\xff\xff\xff\xff\xff\xff\xff\x7f"
        },
        {
          int: 0x8000_0000_0000_0000,
          str: "\x00\x00\x00\x00\x00\x00\x00\x80"
        }
      ],
      signed: [
        {
          int: 0x7fff_ffff_ffff_ffff,
          str: "\xff\xff\xff\xff\xff\xff\xff\x7f"
        },
        {
          int: -0x8000_0000_0000_0000,
          str: "\x00\x00\x00\x00\x00\x00\x00\x80"
        }
      ]
    },
    native: {
      unsigned: [
        {
          int: 0x7fff_ffff_ffff_ffff,
          str: [0x7fff_ffff_ffff_ffff].pack('Q')
        },
        {
          int: 0x8000_0000_0000_0000,
          str: [0x8000_0000_0000_0000].pack('Q')
        }
      ],
      signed: [
        {
          int: 0x7fff_ffff_ffff_ffff,
          str: [0x7fff_ffff_ffff_ffff].pack('q')
        },
        {
          int: -0x8000_0000_0000_0000,
          str: [0x8000_0000_0000_0000].pack('q')
        }
      ]
    }
  }.freeze

  %i[unsigned signed].each do |us|
    %i[big little native].each do |endian|
      suffix = case endian
               when :little then 'le'
               when :native then 'n'
               else ''
               end
      prefix = us == :signed ? 'S' : ''
      klass = BinStruct.const_get("#{prefix}Int64#{suffix}")
      RSpec.describe klass do
        before(:each) { @int = klass.new }
        it "#read an unsigned 64-bit #{endian}-endian integer" do
          fixtures = INT64[endian][us]
          expect(@int.read(fixtures[0][:str]).to_i).to eq(fixtures[0][:int])
          expect(@int.read(fixtures[1][:str]).to_i).to eq(fixtures[1][:int])
        end
        it "#to_s binarize an unsigned 64-bit #{endian}-endian integer" do
          fixtures = INT64[endian][us]
          expect(@int.from_human(fixtures[0][:int]).to_s).to eq(fixtures[0][:str].b)
          expect(@int.from_human(fixtures[1][:int]).to_s).to eq(fixtures[1][:str].b)
        end
        it '#sz returns 8' do
          expect(@int.sz).to eq(8)
        end
      end
    end
  end
end
