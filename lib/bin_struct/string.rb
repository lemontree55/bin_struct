# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

require 'forwardable'

module BinStruct
  # This class mimics regular String, but it is {Structable}.
  #
  # It may take its length from another field ({LengthFrom} capacity). It may also has a static length
  # (i.e. string has always the same length, whatever its content is).
  #
  # @example Basic example
  #   str = BinStruct::String.new
  #   str.read("abc")
  #   str.to_s #=> "abc".b
  #
  # @example LengthFrom example
  #   class StrLen < BinStruct::Struct
  #     define_attr :length, BinStruct::Int8
  #     define_attr :str, BinStruct::String, builder: ->(h, t) { t.new(length_from: h[:length]) }
  #   end
  #
  #   # Length is 3, but rest of data is 4 byte long. Only 3 bytes will be read.
  #   s = StrLen.new.read("\x03abcd")
  #   s.length #=> 3
  #   s.str.to_s #=> "abc".b
  #   s.to_s # => "\x03abc".b
  #
  # @example static length example
  #   s = BinStruct::String.new(static_length: 10)
  #   s.sz #=> 10
  #   s.to_s #=> "\0\0\0\0\0\0\0\0\0\0".b
  #   s.read("01234567890123456789")
  #   s.to_s #=> "0123456789".b
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class String
    extend Forwardable
    include Structable
    include LengthFrom

    def_delegators :@string, :[], :length, :size, :inspect, :==,
                   :unpack, :force_encoding, :encoding, :index, :empty?,
                   :encode, :slice, :slice!, :[]=, :b

    # Underlying Ruby String
    # @return [::String]
    attr_reader :string
    # String static length, if set
    # @return [Integer]
    attr_reader :static_length

    # @param [Hash] options
    # @option options [Int,Proc] :length_from object or proc from which
    #   takes length when reading
    # @option options [Integer] :static_length set a static length for this string
    # @option options [::String] :value string value (default to +""+)
    def initialize(options = {})
      register_internal_string(options[:value] || +'')
      initialize_length_from(options)
      @static_length = options[:static_length]
    end

    # Initialize object on copying:
    # * duplicate underlying Ruby String
    # @return [void]
    def initialize_copy(_orig)
      @string = @string.dup
    end

    # Populate String from a binary String. Limit length using {LengthFrom} or {#static_length}, if one is set.
    # @param [::String,nil] str
    # @return [self]
    def read(str)
      s = read_with_length_from(str)
      register_internal_string(s)
      self
    end

    alias old_sz_to_read sz_to_read
    private :old_sz_to_read

    # Size to read.
    # Computed from {#static_length} or +length_from+, if one defined.
    # @return [Integer]
    def sz_to_read
      return static_length if static_length?

      old_sz_to_read
    end

    # Say if a static length is defined
    # @return [Boolean]
    def static_length?
      !static_length.nil?
    end

    # Format String when inspecting from a {Struct}
    # @return [::String]
    def format_inspect
      inspect
    end

    # Append the given string to String
    # @param [#to_s] str
    # @return [self]
    def <<(str)
      @string << str.to_s.b
      self
    end

    # Generate "binary" string
    # @return [::String]
    def to_s
      if static_length?
        s = @string[0, static_length]
        s << ("\x00" * (static_length - s.length))
        s.b
      else
        @string.b
      end
    end

    alias to_human to_s
    alias from_human read

    private

    def register_internal_string(str)
      @string = str.b
    end
  end
end
