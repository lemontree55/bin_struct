# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

require_relative 'bin_struct/version'

# BinStruct module provides classes to easily serialize/deserialize data to/from binary strings.
# @example Basic example
#   class MyData < BinStruct::Struct
#     # Define 2 attributes as a 8-bit integer
#     define_attr :byte1, BinStruct::Int8
#     define_attr :byte2, BinStruct::Int8
#     # Define an attribute as a 16-bit big endian integer
#     define_attr :word, BinStruct::Int16
#     # Define a 32-bit little endian integer attribute
#     define_attr :dword, BinStruct::Int32le
#     # Define a string prepending with its length (8-bit integer)
#     define_attr :str, BinStruct::IntString
#   end
#
#   # Generate binary data
#   mydata = MyData.new(byte1: 1, byte2: 2, word: 3, dword: 4, str: 'abc')
#   mydata.to_s  #=> "\x01\x02\x00\x03\x04\x00\x00\x00\x03abc".b
#
#   # Parse binary data
#   mydata.read("\x00\xff\x01\x23\x11\x22\x33\x44\x00")
#   mydata.byte1 #=> 0
#   mydata.byte2 #=> 255
#   mydata.word  #=> 0x0123
#   mydata.dword #=> 0x44332211
#   mydata.str #=> ""
# @author LemonTree55
module BinStruct
  # BinStruct error class
  class Error < StandardError; end

  # Force binary encoding for +str+
  # @param [String] str
  # @return [String] binary encoded string
  # @deprecated Use {::String#b} instead of this method
  def self.force_binary(str)
    str.b
  end
end

require_relative 'bin_struct/structable'
require_relative 'bin_struct/int'
require_relative 'bin_struct/enum'
require_relative 'bin_struct/bit_attr'
require_relative 'bin_struct/struct'
require_relative 'bin_struct/length_from'
require_relative 'bin_struct/abstract_tlv'
require_relative 'bin_struct/array'
require_relative 'bin_struct/string'
require_relative 'bin_struct/cstring'
require_relative 'bin_struct/int_string'
require_relative 'bin_struct/oui'
