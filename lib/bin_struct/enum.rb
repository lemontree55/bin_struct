# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

module BinStruct
  # @abstract Base enum class to handle binary integers with limited
  #   authorized values
  # An {Enum} type is used to handle an {Int} attribute with limited
  # and named values.
  #
  # == Simple example
  #  enum = Int8Enum.new('low' => 0, 'medium' => 1, 'high' => 2})
  # In this example, +enum+ is a 8-bit attribute which may take one
  # among three values: +low+, +medium+ or +high+:
  #  enum.value = 'high'
  #  enum.value              # => 2
  #  enum.value = 1
  #  enum.value              # => 1
  #  enum.to_human           # => "medium"
  # Setting an unknown value will raise an exception:
  #  enum.value = 4          # => raise!
  #  enum.value = 'unknown'  # => raise!
  # But {#read} will not raise when reading an outbound value. This
  # to enable decoding (or forging) of bad packets.
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class Enum < Int
    # Enumerated values
    # @return [Hash{::String => Integer}]
    attr_reader :enum

    # @param [Hash] options
    # @see Int#initialize
    # @option options [Hash{::String => Integer}] :enum enumerated values. Default value is taken from
    #   first element unless given. This option is mandatory.
    # @option options [Integer,::String] :default
    # @author LemonTree55
    def initialize(options = {})
      enum = options[:enum]
      raise TypeError, 'enum must be defined as a Hash' unless enum.is_a?(Hash)

      options[:default] ||= enum[enum.keys.first]
      super
      @enum = enum
    end

    # Setter for value attribute
    # @param [#to_i, String,nil] value value as an Integer or as a String
    #   from enumration
    # @return [Integer]
    # @raise [ArgumentError] String value is unknown
    def value=(value)
      ival = case value
             when NilClass
               nil
             when ::String
               raise ArgumentError, "#{value.inspect} not in enumeration" unless @enum.key?(value)

               @enum[value]
             else
               value.to_i
             end
      @value = ival
    end

    # To handle human API: set value from a String
    alias from_human value=

    # Get human readable value (enum name)
    # @return [::String]
    def to_human
      @enum.key(to_i) || "<unknown:#{@value}>"
    end

    # Format Enum type when inspecting Struct
    # @return [::String]
    def format_inspect
      format_str % [to_human, to_i]
    end
  end

  # Enumeration on one byte. See {Enum}.
  # @author LemonTree55
  class Int8Enum < Enum
    # @param [Hash] options
    # @option options [Hash{::String => Integer}] :enum enumerated values. Default value is taken from
    #   first element unless given. This option is mandatory.
    # @option options [Integer,::String] :value
    # @option options [Integer,::String] :default
    def initialize(options = {})
      opts = options.slice(:enum, :value, :default)
      opts[:width] = 1
      opts[:endian] = nil
      super(opts)
      @packstr = { nil => 'C' }
    end
  end

  # Enumeration on 2-byte integer. See {Enum}.
  # @author LemonTree55
  class Int16Enum < Enum
    # @param [Hash] options
    # @option options [Hash{::String => Integer}] :enum enumerated values. Default value is taken from
    #   first element unless given. This option is mandatory.
    # @option options [:big,:little] :endian
    # @option options [Integer,::String] :value
    # @option options [Integer,::String] :default
    def initialize(options = {})
      opts = options.slice(:enum, :endian, :default, :value)
      opts[:endian] ||= :big
      opts[:width] = 2
      super(opts)
      @packstr = { big: 'n', little: 'v' }
    end
  end

  # Enumeration on big endian 2-byte integer. See {Enum}.
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class Int16beEnum < Int16Enum
    undef endian=

    # @param [Hash] options
    # @option options [Hash{::String => Integer}] :enum enumerated values. Default value is taken from
    #   first element unless given. This option is mandatory.
    # @option options [Integer,::String] :value
    # @option options [Integer,::String] :default
    def initialize(options = {})
      opts = options.slice(:enum, :default, :value)
      opts[:endian] = :big
      super(opts)
    end
  end

  # Enumeration on little endian 2-byte integer. See {Enum}.
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class Int16leEnum < Int16Enum
    undef endian=

    # @param [Hash] options
    # @option options [Hash{::String => Integer}] :enum enumerated values. Default value is taken from
    #   first element unless given. This option is mandatory.
    # @option options [Integer,::String] :value
    # @option options [Integer,::String] :default
    def initialize(options = {})
      opts = options.slice(:enum, :default, :value)
      opts[:endian] = :little
      super(opts)
    end
  end

  # Enumeration on 4-byte integer. See {Enum}.
  # @author LemonTree55
  class Int32Enum < Enum
    # @param [Hash] options
    # @option options [Hash{::String => Integer}] :enum enumerated values. Default value is taken from
    #   first element unless given. This option is mandatory.
    # @option options [:big,:little] :endian
    # @option options [Integer,::String] :value
    # @option options [Integer,::String] :default
    def initialize(options = {})
      opts = options.slice(:enum, :endian, :default, :value)
      opts[:endian] ||= :big
      opts[:width] = 4
      super(opts)
      @packstr = { big: 'N', little: 'V' }
    end
  end

  # Enumeration on big endian 4-byte integer. See {Enum}.
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class Int32beEnum < Int32Enum
    undef endian=

    # @param [Hash] options
    # @option options [Hash{::String => Integer}] :enum enumerated values. Default value is taken from
    #   first element unless given. This option is mandatory.
    # @option options [Integer,::String] :value
    # @option options [Integer,::String] :default
    def initialize(options = {})
      opts = options.slice(:enum, :default, :value)
      opts[:endian] = :big
      super(opts)
    end
  end

  # Enumeration on little endian 4-byte integer. See {Enum}.
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class Int32leEnum < Int32Enum
    undef endian=

    # @param [Hash] options
    # @option options [Hash{::String => Integer}] :enum enumerated values. Default value is taken from
    #   first element unless given. This option is mandatory.
    # @option options [Integer,::String] :value
    # @option options [Integer,::String] :default
    def initialize(options = {})
      opts = options.slice(:enum, :default, :value)
      opts[:endian] = :little
      super(opts)
    end
  end
end
