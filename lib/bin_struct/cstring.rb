# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

require 'forwardable'

module BinStruct
  # This class handles null-terminated strings (aka C strings).
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class CString
    extend Forwardable
    include Structable

    # @!method [](index)
    #   @overload [](index)
    #     Return the character at +index+.
    #     @param [Integer] index
    #   @overload [](start, length)
    #     Return the substring starting at +start+ with +length+ length.
    #     @param [Integer] start
    #     @param [Integer] length
    #   @return [::String,nil]
    # @!method length
    #   Return string length (without null-terminator)
    #   @return [Integer]
    # @method size
    #   Return string length (without null-terminator)
    #   @return [Integer]
    #   @see #length
    # @!method ==
    #   Check equality with underlying Ruby String
    #   @return [Boolean]
    # @!method unpack
    #   Apply unpack on underlying Ruby String
    #   @see ::String#unpack
    #   @return [::Array]
    # @!method force_encoding
    #   @see ::String#force_encoding
    # @!method encoding
    #   @see ::String#encoding
    #   @return [Encoding]
    # @!method index(substring, offset = 0)
    #   Returns the Integer index of the first occurrence of the given substring, or +nil+ if none found.
    #   @param [::String] substring
    #   @param [Integer] offset
    #   @return [Integer,nil]
    # @!method empty?
    #   Return +true+ is string is empty.
    #   @return [Boolean]
    # @!method encode(encoding, **options)
    #   @return [::String]
    #   @see ::String#encode
    # @!method slice(*args)
    #   Returns the substring of +self+ specified by the arguments.
    #   @see ::String#slice
    #   @return [String,nil]
    # @!method slice!(*args)
    #   Removes the substring of +self+ specified by the arguments; returns the removed substring.
    #   @see ::String#slice!
    #   @return [String,nil]
    def_delegators :@string, :[], :length, :size, :inspect, :==,
                   :unpack, :force_encoding, :encoding, :index, :empty?,
                   :encode, :slice, :slice!

    # Underlying Ruby String
    # @return [::String]
    attr_reader :string
    # Static length, if any
    # @return [Integer,nil]
    attr_reader :static_length

    # @param [Hash] options
    # @option options [Integer] :static_length set a static length for this string
    def initialize(options = {})
      register_internal_string(+'')
      @static_length = options[:static_length]
    end

    # Populate self from binary string
    # @param [::String] str
    # @return [self]
    def read(str)
      s = str.to_s
      s = s[0, static_length] if static_length?
      register_internal_string s
      remove_null_character
      self
    end

    # Get null-terminated string
    # @return [::String]
    def to_s
      if static_length?
        s = string[0, static_length - 1]
        s << ("\x00" * (static_length - s.length))
      else
        s = "#{string}\x00"
      end
      BinStruct.force_binary(s)
    end

    # Append the given string to CString
    # @param [#to_s] str
    # @return [self]
    def <<(str)
      @string << str.to_s
      remove_null_character
      self
    end

    # Get C String size in bytes
    # @return [Integer]
    def sz
      if static_length?
        static_length
      else
        to_s.size
      end
    end

    # Say if a static length is defined
    # @return [Boolean]
    def static_length?
      !static_length.nil?
    end

    # Populate CString from a human readable string
    # @param [::String] str
    # @return [self]
    def from_human(str)
      read str
    end

    # Get human-readable string
    # @return [::String]
    def to_human
      string
    end

    private

    def register_internal_string(str)
      @string = str
      BinStruct.force_binary(@string)
    end

    def remove_null_character
      idx = string.index(0.chr)
      register_internal_string(string[0, idx]) unless idx.nil?
    end
  end
end
