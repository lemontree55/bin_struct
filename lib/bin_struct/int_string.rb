# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

module BinStruct
  # Provides a class for creating strings preceeded by their length as an {Int}.
  # By default, a null string will have one byte length (length byte set to 0).
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class IntString
    include Structable

    # internal string
    # @return [::String]
    attr_reader :string

    # @param [Hash] options
    # @option options [Class] :length_type should be a {Int} subclass. Default to {Int8}.
    # @option options [::String] :value String value. Default to +""+
    def initialize(options = {})
      @string = BinStruct::String.new.read(options[:value] || +'')
      @length = (options[:length_type] || Int8).new
      calc_length
    end

    # Populate IntString from a binary String
    # @param [::String] str
    # @return [self]
    def read(str)
      unless str[0, @length.width].size == @length.width
        raise Error,
              "String too short for type #{@length.class.to_s.gsub(/.*::/, '')}"
      end
      @length.read str[0, @length.width]
      @string.read str[@length.width, @length.to_i]
      self
    end

    # Set length
    # @param [Integer] len
    # @return [Integer]
    def length=(len)
      @length.from_human(len)
      # rubocop:disable Lint/Void
      len
      # rubocop:enable Lint/Void
    end

    # Get length as registered in +IntLength+
    # @return [Integer]
    def length
      @length.to_i
    end

    # Set string without setting {#length}
    # @param [#to_s] str
    # @return [::String]
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
    # @param [::String] str
    # @return [self]
    def from_human(str)
      @string.read(str)
      calc_length
      self
    end

    # Get human readable string
    # @return [::String]
    def to_human
      @string
    end

    # Set length from internal string length
    # @return [Integer]
    def calc_length
      @length.from_human(@string.length)
    end

    # Give binary string length (including +length+ attribute)
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
