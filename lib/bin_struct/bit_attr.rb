# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.
require 'digest'

module BinStruct
  # Define a bitfield attribute to embed in a {Struct}.
  #
  #  class MyStruct < BinStruct::Struct
  #    # Create a 32-bit bitfield attribute, with fields a (16 bits), b and c (4 bits each) and d (8 bits).
  #    # a is the leftmost field in bitfield, and d the rightmost one.
  #    define_attr :int32, BinStruct::BitAttr.create(width: 32, a: 16, b: 4, c: 4, d:8)
  #  end
  # @since 0.3.0
  # @author LemonTree55
  class BitAttr
    include Structable

    # @return [Integer] width in bits of bit attribute
    attr_reader :width
    # @return [Array[Symbol]]
    attr_reader :bit_methods

    # @private
    Parameters = Struct.new(:width, :fields, :int)

    class << self
      @cache = {}

      # @private
      # @return [Parameters]
      attr_reader :parameters

      # Create a new {BitAttr} subclass with specified parameters
      # @param [Integer] width size of bitfields in bits. Must be a size of an {Int} (8, 16, 24, 32 or 64 bits).
      # @param [:big,:little,:native] endian endianess of bit attribute as an integer
      # @param [Hash{Symbol=>Integer}] fields hash associating field names with their size. Total size MUST be equal
      #    to +width+.
      # @return [Class]
      # @raise [ArgumentError] raise if:
      #    * width is not a size of one of {Int} subclasses,
      #    * sum of bitfield sizes is not equal to +width+
      def create(width:, endian: :big, **fields)
        raise ArgumentError, 'with must be 8, 16, 24, 32 or 64' unless [8, 16, 24, 32, 64].include?(width)

        hsh = compute_hash(width, endian, fields)
        cached = cache[hsh]
        return cached if cached

        total_size = fields.reduce(0) { |acc, ary| acc + ary.last }
        raise ArgumentError, "sum of bitfield sizes is not equal to #{width}" unless total_size == width

        cache[hsh] = Class.new(self) do
          int_klass = BinStruct.const_get("Int#{width}")
          @parameters = Parameters.new(width, fields, int_klass.new(endian: endian)).freeze
        end
      end

      private

      # @return [Hash{::String=>Class}]
      def cache
        return @cache if defined? @cache

        @cache = {}
      end

      # @param [::Array] params
      # @return [::String]
      def compute_hash(*params)
        Digest::MD5.digest(Marshal.dump(params))
      end
    end

    # Initialize bit attribute
    # @param [Hash{Symbol=>Integer}] opts initialization values for fields, where keys are field names and values are
    #     initialization values
    # @return [self]
    def initialize(opts = {})
      parameters = self.class.parameters
      raise NotImplementedError, '#initialize may only be called on subclass of {self.class}' if parameters.nil?

      @width = parameters.width
      @fields = parameters.fields
      @int = parameters.int.dup
      @data = {}
      @bit_methods = []

      parameters.fields.each do |name, size|
        @data[name] = opts[name] || 0
        define_methods(name, size)
      end
      @bit_methods.freeze
    end

    # Populate bit attribute from +str+
    # @param [::String,nil] str
    # @return [self]
    def read(str)
      return self if str.nil?

      @int.read(str)
      compute_data(@int.to_i)
    end

    # Give integer associated to this attribute
    # @return [Integer]
    def to_i
      v = 0
      @fields.each do |name, size|
        v <<= size
        v |= @data[name]
      end

      v
    end
    alias to_human to_i

    # Return binary string
    # @return [::String]
    def to_s
      @int.value = to_i
      @int.to_s
    end

    # Set fields from associated integer
    # @param [#to_i] value
    # @return [self]
    def from_human(value)
      compute_data(value.to_i)
    end

    private

    # @param [Integer] value
    # @return [self]
    def compute_data(value)
      @fields.reverse_each do |name, size|
        @data[name] = value & ((2**size) - 1)
        value >>= size
      end

      self
    end

    # @param [Symbol] name
    # @return [void]
    def define_methods(name, size)
      instance_eval "def #{name}; @data[#{name.inspect}]; end\n", __FILE__, __LINE__ # def name; data[:name]; end
      bit_methods << name
      bit_methods << :"#{name}="

      # rubocop:disable Style/DocumentDynamicEvalDefinition
      if size == 1
        instance_eval "def #{name}?; @data[#{name.inspect}] != 0; end\n", __FILE__, __LINE__
        instance_eval "def #{name}=(val); v = case val when TrueClass; 1 when FalseClass; 0 else val end; " \
                      "@data[#{name.inspect}] = v; end", __FILE__, __LINE__ - 2
        bit_methods << :"#{name}?"
      else
        instance_eval "def #{name}=(val); @data[#{name.inspect}] = val; end", __FILE__, __LINE__
      end
      # rubocop:enable Style/DocumentDynamicEvalDefinition
    end
  end
end
