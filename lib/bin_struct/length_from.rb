# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

module BinStruct
  # This module is a mixin adding +length_from+ capacity to a type.
  # +length_from+ capacity is the capacity, for a type, to gets its
  # length from another object. For an example, see {String}.
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  module LengthFrom
    # Max value returned by {#sz_to_read}.
    MAX_SZ_TO_READ = 65_535

    # Initialize +length_from+ capacity.
    # Should be called by extended object's initialize method.
    # @param [Hash] options
    # @option options [Int,Proc] :length_from object or proc from which
    #   takes length when reading
    # @return [void]
    def initialize_length_from(options)
      @length_from = options[:length_from]
    end

    # Return a substring from +str+ of length given in another object.
    # @param [#to_s] str
    # @return [::String]
    def read_with_length_from(str)
      s = str.to_s.b
      s[0, sz_to_read]
    end

    # Size to read, from length_from
    # @return [Integer]
    def sz_to_read
      len = case @length_from
            when Int
              @length_from.to_i
            when Proc
              @length_from.call
            else
              MAX_SZ_TO_READ
            end
      [0, len].max
    end
  end
end
