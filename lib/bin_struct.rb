# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

require_relative 'bin_struct/version'

# BinStruct module
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
