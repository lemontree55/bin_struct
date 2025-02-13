# frozen_string_literal: true

# This file is part of BinStruct
# See https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

module BinStruct
  # Base integer class to handle binary integers
  # @abstract
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class Int
    include Structable

    # Integer value
    # @return [Integer,nil]
    attr_accessor :value
    # Integer endianness
    # @return [:little,:big,:native,nil]
    attr_accessor :endian
    # Integer size, in bytes
    # @return [Integer]
    attr_accessor :width
    # Integer default value
    # @return [Integer]
    attr_accessor :default

    # @param [Hash] options
    # @option options [Integer, nil] :value Value to set Int to
    # @option options [:little,:big,:native,nil] :endian Int's endianess
    # @option options [Integer,nil] :width Int's width in bytes
    # @option options [Integer] :default Default value to use when {#value} is not set (Default to +0+).
    # @author LemonTree55
    def initialize(options = {})
      @value = options[:value]
      @endian = options[:endian]
      @width = options[:width] || 0
      @default = options[:default] || 0
    end

    # @abstract
    # Read an Int from a binary string or an integer
    # @param [#to_s] str
    # @return [self]
    # @raise [Error] when reading +#to_s+ objects with abstract Int class.
    # @author LemonTree55
    def read(str)
      raise Error, 'BinStruct::Int#read is abstract' unless defined? @packstr

      @value = str.to_s.unpack1(@packstr[@endian])
      self
    end

    # @abstract
    # @return [::String]
    # @raise [Error] This is an abstract method and must be redefined
    def to_s
      raise Error, 'BinStruct::Int#to_s is abstract' unless defined? @packstr

      [to_i].pack(@packstr[@endian])
    end

    # Convert Int to Integer
    # @return [Integer]
    def to_i
      @value || @default
    end
    alias to_human to_i

    # Initialize value from an Integer.
    # @param [Integer] value
    # @return [self]
    def from_human(value)
      @value = value
      self
    end

    # Convert Int to Float
    # @return [Float]
    def to_f
      to_i.to_f
    end

    # Give size in bytes of self
    # @return [Integer]
    def sz
      width
    end

    # Format Int type when inspecting Struct
    # @return [::String]
    def format_inspect
      format_str % [to_i.to_s, to_i]
    end

    # Return the number of bits used to encode this Int
    # @return [Integer]
    def nbits
      width * 8
    end

    private

    def format_str
      "%-16s (0x%0#{width * 2}x)"
    end
  end

  # One byte unsigned integer
  # @author LemonTree55
  class Int8 < Int
    # @param [Hash] options
    # @option options [Integer,nil] :value
    def initialize(options = {})
      options[:endian] = nil
      options[:width] = 1
      super
      @packstr = { nil => 'C' }
    end
  end

  # One byte signed integer
  # @author LemonTree55
  class SInt8 < Int
    # @param [Hash] options
    # @option options [Integer,nil] :value
    def initialize(options = {})
      options[:endian] = nil
      options[:width] = 1
      super
      @packstr = { nil => 'c' }
    end
  end

  # 2-byte unsigned integer
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class Int16 < Int
    # @param [Hash] options
    # @option options [Integer,nil] :value
    # @option options [:big,:little,:native] :endian
    def initialize(options = {})
      opts = { value: options[:value], endian: options[:endian] || :big, width: 2 }
      super(opts)
      @packstr = { big: 'n', little: 'v', native: 'S' }
    end
  end

  # Big endian 2-byte unsigned integer
  # @author Sylvain Daubert (2016-2024)
  class Int16be < Int16
    undef endian=
  end

  # Little endian 2-byte unsigned integer
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class Int16le < Int16
    undef endian=

    # @param [Hash] options
    # @option options [Integer,nil] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :little }
      super(opts)
    end
  end

  # Native endian 2-byte unsigned integer
  # @author LemonTree55
  class Int16n < Int16
    undef endian=

    # @param [Hash] options
    # @option options [Integer,nil] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :native }
      super(opts)
    end
  end

  # 2-byte signed integer
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class SInt16 < Int16
    # @param [Hash] options
    # @option options [Integer,nil] :value
    # @option options [:big,:little,:native] :endian
    def initialize(options = {})
      opts = { value: options[:value], endian: options[:endian] || :big }
      super(opts)
      @packstr = { big: 's>', little: 's<', native: 's' }
    end
  end

  # Big endian 2-byte signed integer
  # @author Sylvain Daubert (2016-2024)
  class SInt16be < SInt16
    undef endian=
  end

  # Little endian 2-byte signed integer
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class SInt16le < SInt16
    undef endian=

    # @param [Hash] options
    # @option options [Integer,nil] :value
    # @author LemonTree55
    def initialize(options = {})
      opts = { value: options[:value], endian: :little }
      super(opts)
    end
  end

  # Native endian 2-byte signed integer
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class SInt16n < SInt16
    undef endian=

    # @param [Hash] options
    # @option options [Integer,nil] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :native }
      super(opts)
    end
  end

  # 3-byte unsigned integer
  # @author LemonTree55
  class Int24 < Int
    # @param [Hash] options
    # @option options [Integer,nil] :value
    # @option options [:big, :little, :native] :endian
    def initialize(options = {})
      opts = options.slice(:value, :endian)
      opts[:endian] ||= :big
      opts[:width] = 3

      if opts[:endian] == :native
        opts[:endian] = if [1].pack('S').unpack1('n') == 1
                          :big
                        else
                          :little
                        end
      end
      super(opts)
    end

    # Read a 3-byte Int from a binary string
    # @param [::String] value
    # @return [self]
    def read(value)
      return self if value.nil?

      up8 = down16 = 0
      if @endian == :big
        up8, down16 = value.to_s.unpack('Cn')
      else
        down16, up8 = value.to_s.unpack('vC')
      end
      @value = (up8 << 16) | down16
      self
    end

    # @author Sylvain Daubert (2016-2024)
    # @return [::String]
    def to_s
      up8 = to_i >> 16
      down16 = to_i & 0xffff
      if @endian == :big
        [up8, down16].pack('Cn')
      else
        [down16, up8].pack('vC')
      end
    end
  end

  # Big endian 3-byte unsigned integer
  # @author Sylvain Daubert (2016-2024)
  class Int24be < Int24
    undef endian=
  end

  # Little endian 3-byte unsigned integer
  # @author LemonTree55
  class Int24le < Int24
    undef endian=

    # @param [Hash] options
    # @option options [Integer] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :little }
      super(opts)
    end
  end

  # Native endian 3-byte unsigned integer
  # @author LemonTree55
  class Int24n < Int24
    undef endian=

    # @param [Hash] options
    # @option options [Integer] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :little }
      super(opts)
    end
  end

  # 4-byte unsigned integer
  # @author LemonTree55
  class Int32 < Int
    # @param [Hash] options
    # @option options [Integer,nil] :value
    # @option options [:big,:little,:native] :endian
    def initialize(options = {})
      opts = { value: options[:value], endian: options[:endian] || :big, width: 4 }
      super(opts)
      @packstr = { big: 'N', little: 'V', native: 'L' }
    end
  end

  # Big endian 4-byte unsigned integer
  # @author Sylvain Daubert (2016-2024)
  class Int32be < Int32
    undef endian=
  end

  # Little endian 4-byte unsigned integer
  # @author LemonTree55
  class Int32le < Int32
    undef endian=

    # @param [Hash] options
    # @option options [Integer,nil] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :little }
      super(opts)
    end
  end

  # Native endian 4-byte unsigned integer
  # @author LemonTree55
  class Int32n < Int32
    undef endian=

    # @param [Hash] options
    # @option options [Integer,nil] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :native }
      super(opts)
    end
  end

  # 4-byte signed integer
  # @author LemonTree55
  class SInt32 < Int32
    # @param [Hash] options
    # @option options [Integer] :value
    # @option options [:big,:little,:native] :endian
    def initialize(options = {})
      opts = { value: options[:value], endian: options[:endian] || :big }
      super(opts)
      @packstr = { big: 'l>', little: 'l<', native: 'l' }
    end
  end

  # Big endian 4-byte signed integer
  # @author Sylvain Daubert (2016-2024)
  class SInt32be < SInt32
    undef endian=
  end

  # Little endian 4-byte signed integer
  # @author LemonTree55
  class SInt32le < SInt32
    undef endian=

    # @param [Hash] options
    # @option options [Integer] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :little }
      super(opts)
    end
  end

  # Native endian 4-byte signed integer
  # @author LemonTree55
  class SInt32n < SInt32
    undef endian=

    # @param [Hash] options
    # @option options [Integer] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :native }
      super(opts)
    end
  end

  # 8-byte unsigned integer
  # @author LemonTree55
  class Int64 < Int
    # @param [Hash] options
    # @option options [Integer] :value
    # @option options [:big,:little,:native] :endian
    def initialize(options = {})
      opts = options.slice(:value, :endian)
      opts[:endian] ||= :big
      opts[:width] = 8
      super(opts)
      @packstr = { big: 'Q>', little: 'Q<', native: 'Q' }
    end
  end

  # Big endian 8-byte unsigned integer
  # @author Sylvain Daubert (2016-2024)
  class Int64be < Int64
    undef endian=
  end

  # Little endian 8-byte unsigned integer
  # @author LemonTree55
  class Int64le < Int64
    undef endian=

    # @param [Hash] options
    # @option options [Integer] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :little }
      super(opts)
    end
  end

  # Native endian 8-byte unsigned integer
  # @author LemonTree55
  class Int64n < Int64
    undef endian=

    # @param [Hash] options
    # @option options [Integer] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :native }
      super(opts)
    end
  end

  # 8-byte signed integer
  # @author LemonTree55
  class SInt64 < Int64
    # @param [Hash] options
    # @option options [Integer] :value
    # @option options [:big,:little,:native] :endian
    def initialize(options = {})
      opts = options.slice(:value, :endian)
      super(opts)
      @packstr = { big: 'q>', little: 'q<', native: 'q' }
    end
  end

  # Big endian 8-byte signed integer
  # @author Sylvain Daubert (2016-2024)
  class SInt64be < SInt64
    undef endian=
  end

  # Little endian 8-byte signed integer
  # @author LemonTree55
  class SInt64le < SInt64
    undef endian=

    # @param [Hash] options
    # @option options [Integer] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :little }
      super(opts)
    end
  end

  # Native endian 8-byte signed integer
  # @author LemonTree55
  class SInt64n < SInt64
    undef endian=

    # @param [Hash] options
    # @option options [Integer] :value
    def initialize(options = {})
      opts = { value: options[:value], endian: :native }
      super(opts)
    end
  end
end
