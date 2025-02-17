# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

module BinStruct
  # OUI type, defined as a set of 3 bytes
  # @example
  #  oui = BinStruct::OUI.new
  #  oui.from_human('00:01:02')
  #  oui.to_human   # => "00:01:02"
  #  oui.to_s       # => "\x00\x01\x02".b
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class OUI < Struct
    include Structable

    # @attribute b2
    #  @return [Integer] left-most byte
    define_attr :b2, Int8
    # @attribute b1
    #  @return [Integer] center byte
    define_attr :b1, Int8
    # @attribute b0
    #  @return [Integer] right-most byte
    define_attr :b0, Int8

    # Read a human-readable string to populate object
    # @param [::String] str
    # @return [self]
    # @raise [ArgumentError] OUI cannot be recognized from +str+
    def from_human(str)
      return self if str.nil?

      bytes = str.split(':')
      raise ArgumentError, 'not a OUI' unless bytes.size == 3

      self[:b2].from_human(bytes[0].to_i(16))
      self[:b1].from_human(bytes[1].to_i(16))
      self[:b0].from_human(bytes[2].to_i(16))
      self
    end

    # Get OUI in human readable form (colon-separated bytes)
    # @return [::String]
    def to_human
      attributes.map { |m| '%02x' % self[m] }.join(':')
    end
  end
end
