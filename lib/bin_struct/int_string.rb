# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

module BinStruct
  # Provides a class for creating strings preceeded by their length as a {Int}.
  # By default, a null string will have one byte length (length byte set to 0).
  # @author Sylvain Daubert
  class IntString
    include Fieldable

    # internal string
    # @return [String]
    attr_reader :string

    # @param [Hash] options
    # @option options [Class] :length_type should be a {Int} subclass. Default to {Int8}.
    # @option options [::String] :string String value. Default to +''+
    def initialize(options = {})
      @string = BinStruct::String.new.read(options[:string] || '')
      @length = (options[:length_type] || Int8).new
      calc_length
    end

    # @param [::String] str
    # @return [IntString] self
    def read(str)
      unless str[0, @length.width].size == @length.width
        raise Error,
              "String too short for type #{@length.class.to_s.gsub(/.*::/, '')}"
      end
      @length.read str[0, @length.width]
      @string.read str[@length.width, @length.to_i]
      self
    end

    # @param [Integer] len
    # @return [Integer]
    def length=(len)
      @length.from_human(len)
    end

    # @return [Integer]
    def length
      @length.to_i
    end

    # @param [#to_s] str
    # @return [String]
    def string=(str)
      @length.value = str.to_s.size
      @string = str.to_s
    end

    # Get binary string
    # @return [::String]
    def to_s
      @length.to_s << @string.to_s
    end

    # Set from a human readable string
    # @param [String] str
    # @return [self]
    def from_human(str)
      @string.read(str)
      calc_length
      self
    end

    # Get human readable string
    # @return [::String]
    # @since 2.2.0
    def to_human
      @string
    end

    # Set length from internal string length
    # @return [Integer]
    def calc_length
      @length.from_human(@string.length)
    end

    # Give binary string length (including +length+ field)
    # @return [Integer]
    def sz
      to_s.size
    end

    # Say if IntString is empty
    # @return [Boolean]
    def empty?
      length.zero?
    end
  end
end
