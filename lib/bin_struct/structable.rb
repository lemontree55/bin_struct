# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

module BinStruct
  # Mixin to define minimal API for a class to be embbeded as an attribute in
  # {Struct} object.
  #
  # == Optional methods
  # This method may, optionally, be defined by structable types:
  # * +from_human+ to load data from a human-readable ruby object (String, Integer,...).
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  module Structable
    # Get type name
    # @return [::String]
    def type_name
      self.class.to_s.split('::').last
    end

    # rubocop:disable Lint/UselessMethodDefinition
    # These methods are defined for documentation.

    # Populate object from a binary string
    # @param [::String] str
    # @return [self]
    # @abstract subclass should overload it.
    def read(str)
      super
    end

    # Return object as a binary string
    # @return [::String]
    # @abstract subclass should overload it.
    def to_s
      super
    end

    # Size of object as binary string
    # @return [Integer]
    def sz
      to_s.size
    end

    # Return a human-readbale object
    # @return [::String,Integer]
    # @abstract subclass should overload it.
    def to_human
      super
    end

    # rubocop:enable Lint/UselessMethodDefinition

    # Format object when inspecting a {Struct} object
    # @return [::String]
    def format_inspect
      to_human.to_s
    end
  end
end
