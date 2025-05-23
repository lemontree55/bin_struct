# frozen_string_literal: true

# This file is part of BinStruct
# See https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

module BinStruct
  # @abstract Base class to define type-length-value data.
  #
  # You have to define a concrete class from AbstractTLV
  #   MyTLV = BinStruct::AbstractTLV.create
  #   MyTLV.define_type_enum 'one' => 1, 'two' => 2
  # This will define a new +MyTLV+ class, subclass of {AbstractTLV}. This class will
  # define 3 attributes:
  # * +#type+, as a {Int8Enum} by default,
  # * +#length+, as a {Int8} by default,
  # * and +#value+, as a {String} by default.
  # +.define_type_enum+ is, here, necessary to define enum hash to be used
  # for +#type+ accessor, as this one is defined as an {Enum}.
  #
  # @example Basic usage
  #   MyTLV = BinStruct::AbstractTLV.create
  #   MyTLV.define_type_enum 'one' => 1, 'two' => 2
  #
  #   tlv = MyTLV.new(type: 1, value: 'abcd')  # automagically set #length from value
  #   tlv.type        #=> 1
  #   tlv.human_type  #=> 'one'
  #   tlv.length      #=> 4
  #   tlv.value       #=> "abcd"
  #
  # @example Change attribute types
  #   # Change type for each attribute
  #   # Type and length are 16-bit big endian integers
  #   # Value is a OUI
  #   MyTLV = BinStruct::AbstractTLV.create(type_class: BinStruct::Int16,
  #                                         length_class: BinStruct::Int16,
  #                                         value_class: BinStruct::OUI)
  #   tlv = MyTLV.new(type: 1, value: '01:02:03')
  #   tlv.type        #=> 1
  #   tlv.length      #=> 3
  #   tlv.value       #=> '01:02:03'
  #   tlv.to_s        #=> "\x00\x01\x00\x03\x01\x02\x03"
  #
  # @example Using aliases
  #   # Type and length are 16-bit big endian integers
  #   # Value is a string
  #   # code is an alias for type
  #   MyTLV = BinStruct::AbstractTLV.create(type_class: BinStruct::Int16,
  #                                         length_class: BinStruct::Int16,
  #                                         aliases: { code: :type })
  #   tlv = MyTLV.new(code: 1, value: 'abcd')
  #   tlv.code        #=> 1
  #   tlv.type        #=> 1
  #   tlv.length      #=> 4
  #   tlv.value       #=> 'abcd'
  #
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class AbstractTLV < Struct
    include Structable

    # @private
    ATTR_TYPES = { 'T' => :type, 'L' => :length, 'V' => :value }.freeze

    class << self
      # Aliases defined in {.create}
      # @return [Hash]
      attr_accessor :aliases
      # @private
      attr_accessor :attr_in_length

      # rubocop:disable Metrics/ParameterLists

      # Generate a TLV class
      # @param [Class] type_class Class to use for +type+
      # @param [Class] length_class Class to use for +length+
      # @param [Class] value_class Class to use for +value+
      # @param [::String] attr_order gives attribute order. Each character in [T,L,V] MUST be present once,
      #   in the desired order.
      # @param [::String] attr_in_length give attributes to compute length on.
      # @return [Class]
      # @raise [Error] Called on {AbstractTLV} subclass
      def create(type_class: Int8Enum, length_class: Int8, value_class: String,
                 aliases: {}, attr_order: 'TLV', attr_in_length: 'V')
        unless equal?(AbstractTLV)
          raise Error,
                '.create cannot be called on a subclass of BinStruct::AbstractTLV'
        end

        klass = Class.new(self)
        klass.aliases = aliases
        klass.attr_in_length = attr_in_length

        check_attr_in_length(attr_in_length)
        check_attr_order(attr_order)
        generate_attributes(klass, attr_order, type_class, length_class, value_class)
        generate_aliases_for(klass, aliases)
        aliases.each do |al, orig|
          klass.instance_eval do
            alias_method al, orig if klass.method_defined?(orig)
            alias_method :"#{al}=", :"#{orig}=" if klass.method_defined?(:"#{orig}=")
          end
        end

        klass
      end
      # rubocop:enable Metrics/ParameterLists

      # On inheritage, copy aliases and attr_in_length
      # @param [Class] klass inheriting class
      # @return [void]
      # @since 0.4.0
      # @author LemonTree55
      def inherited(klass)
        super

        aliases = @aliases.clone
        attr_in_length = @attr_in_length.clone

        klass.class_eval do
          @aliases = aliases
          @attr_in_length = attr_in_length
        end
      end

      # Derive a new TLV class from an existing one
      # @param [Class,nil] type_class New class to use for +type+. Unchanged if +nil+.
      # @param [Class,nil] length_class New class to use for +length+. Unchanged if +nil+.
      # @param [Class,nil] value_class New class to use for +value+. Unchanged if +nil+.
      # @return [Class]
      # @raise [Error] Called on {AbstractTLV} class
      # @since 0.4.0
      # @author LemonTree55
      # @example
      #   # TLV with type and length on 16 bits, value is a BinStruct::String
      #   FirstTLV = BinStruct::AbstractTLV.create(type_class: BinStruct::Int16, length_class: BinStruct::Int16)
      #   # TLV with same type and length classes than FirstTLV, but value is an array of Int8
      #   SecondTLV = FirstTLV.derive(value_class: BinStruct::ArrayOfInt8)
      def derive(type_class: nil, length_class: nil, value_class: nil, aliases: {})
        raise Error, ".derive cannot be called on #{name}" if equal?(AbstractTLV)

        klass = Class.new(self)
        klass.aliases.merge!(aliases)
        generate_aliases_for(klass, aliases)

        klass.attr_defs[:type].type = type_class unless type_class.nil?
        klass.attr_defs[:length].type = length_class unless length_class.nil?
        klass.attr_defs[:value].type = value_class unless value_class.nil?

        klass
      end

      # @!attribute type
      #   @abstract
      #   Type attribute for real TLV class
      #   @return [Integer]
      # @!attribute length
      #   @abstract
      #   Length attribute for real TLV class
      #   @return [Integer]
      # @!attribute value
      #   @abstract
      #   Value attribute for real TLV class
      #   @return [Object]

      # @abstract Should only be called on real TLV classes, created by {.create}.
      # Set enum hash for {#type} attribute.
      # @param [Hash{::String, Symbol => Integer}] hsh enum hash
      # @return [void]
      def define_type_enum(hsh)
        attr_defs[:type][:options][:enum].clear
        attr_defs[:type][:options][:enum].merge!(hsh)
      end

      # @abstract Should only be called on real TLV classes, created by {.create}.
      # Set default value for {#type} attribute.
      # @param [Integer,::String,Symbol,nil] default default value from +hsh+ for type
      # @return [void]
      def define_type_default(default)
        attr_defs[:type][:default] = default
      end

      private

      def check_attr_in_length(attr_in_length)
        return if /^[TLV]{1,3}$/.match?(attr_in_length)

        raise 'attr_in_length must only contain T, L and/or V characters'
      end

      def check_attr_order(attr_order)
        if attr_order.match(/^[TLV]{3,3}$/) &&
           (attr_order[0] != attr_order[1]) &&
           (attr_order[0] != attr_order[2]) &&
           (attr_order[1] != attr_order[2])
          return
        end

        raise 'attr_order must contain all three letters TLV, each once'
      end

      def generate_attributes(klass, attr_order, type_class, length_class, value_class)
        attr_order.each_char do |attr_type|
          case attr_type
          when 'T'
            if type_class < Enum
              klass.define_attr(:type, type_class, enum: {})
            else
              klass.define_attr(:type, type_class)
            end
          when 'L'
            klass.define_attr(:length, length_class)
          when 'V'
            klass.define_attr(:value, value_class)
          end
        end
      end

      def generate_aliases_for(klass, aliases)
        aliases.each do |al, orig|
          klass.instance_eval do
            alias_method al, orig if klass.method_defined?(orig)
            alias_method :"#{al}=", :"#{orig}=" if klass.method_defined?(:"#{orig}=")
          end
        end
      end
    end

    # @!attribute type
    #   @abstract
    #   Type attribute
    #   @return [Integer]
    # @!attribute length
    #   @abstract
    #   Length attribute
    #   @return [Integer]
    # @!attribute value
    #   @abstract
    #   Value attribute
    #   @return [Object]enum

    # @abstract Should only be called on real TLV classes, created by {.create}.
    # Return a new instance of a real TLV class.
    # @param [Hash] options
    # @option options [Integer] :type
    # @option options [Integer] :length
    # @option options [Object] :value
    def initialize(options = {})
      @attr_in_length = self.class.attr_in_length
      self.class.aliases.each do |al, orig|
        options[orig] = options[al] if options.key?(al)
      end

      super
      # used #value= defined below, which set length if needed
      self.value = options[:value] if options[:value]
      calc_length unless options.key?(:length)
    end

    # @abstract Should only be called on real TLV class instances.
    # Populate object from a binary string
    # @param [::String,nil] str
    # @return [AbstractTLV] self
    def read(str)
      return self if str.nil?

      idx = 0
      attributes.each do |attr_name|
        attr = self[attr_name]
        length = attr_name == :value ? real_length : attr.sz
        attr.read(str[idx, length])
        idx += attr.sz
      end

      self
    end

    # @abstract Should only be called on real TLV class instances.
    # Set +value+. May set +length+ if value is a {Types::String}.
    # @param [Object] val
    # @return [Object]
    def value=(val)
      if val.is_a?(self[:value].class)
        self[:value] = val
      elsif self[:value].respond_to?(:from_human)
        self[:value].from_human(val)
      else
        self[:value].read(val)
      end
      calc_length
    end

    # @abstract Should only be called on real TLV class instances.
    # Get human-readable type
    # @return [::String]
    def human_type
      self[:type].to_human.to_s
    end

    # @abstract Should only be called on real TLV class instances.
    # @return [::String]
    def to_human
      my_value = self[:value].is_a?(String) ? self[:value].inspect : self[:value].to_human
      'type:%s,length:%u,value:%s' % [human_type, length, my_value]
    end

    # Calculate length
    # @return [Integer]
    def calc_length
      ail = @attr_in_length

      length = 0
      ail.each_char do |attr_type|
        length += self[ATTR_TYPES[attr_type]].sz
      end
      self.length = length
    end

    private

    def real_length
      length = self.length
      length -= self[:type].sz if @attr_in_length.include?('T')
      length -= self[:length].sz if @attr_in_length.include?('L')
      length
    end
  end
end
