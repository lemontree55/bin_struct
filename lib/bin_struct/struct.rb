# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

# rubocop:disable Metrics/ClassLength

module BinStruct
  # @abstract Set of attributes
  # This class is a base class to define headers or anything else with a binary
  # format containing multiple attributes.
  #
  # == Basics
  # A {Struct} subclass is generaly composed of multiple binary attributes. These attributes
  # have each a given type. All {Structable} types are supported.
  #
  # To define a new subclass, it has to inherit from {Struct}. And some class
  # methods have to be used to declare attributes:
  #   class MyBinaryStructure < BinStruct::Struct
  #     # define a first Int8 attribute, with default value: 1
  #     define_attr :attr1, BinStruct::Int8, default: 1
  #     #define a second attribute, of kind Int32
  #     define_attr :attr2, BinStruct::Int32
  #   end
  #
  # These defintions create 4 methods: +#attr1+, +#attr1=+, +#attr2+ and +#attr2=+.
  # All these methods take and/or return Integers.
  #
  # Attributes may also be accessed through {#[]} ans {#[]=}. These methods give access
  # to type object:
  #   mybs = MyBinaryStructure.new
  #   mybs.attr1     # => Integer
  #   mybs[:attr1]   # => BinStruct::Int8
  #
  # {#initialize} accepts an option hash to populate attributes. Keys are attribute
  # name symbols, and values are those expected by writer accessor.
  #
  # {#read} is able to populate object from a binary string.
  #
  # {#to_s} returns binary string from object.
  #
  # == Add attributes
  # {.define_attr} adds an attribute to Struct subclass. A lot of attribute types may be
  # defined: integer types, string types (to handle a stream of bytes). More
  # complex attribute types may be defined using others Struct subclasses:
  #   # define a 16-bit little-endian integer attribute, named type
  #   define_attr :type, BinStruct::Int16le
  #   # define a string attribute
  #   define_attr :body, BinStruct::String
  #   # define a attribute using a complex type (Struct subclass)
  #   define_attr :oui, BinStruct::OUI
  #
  # This example creates six methods on our Struct subclass: +#type+, +#type=+,
  # +#body+, +#body=+, +#mac_addr+ and +#mac_addr=+.
  #
  # {.define_attr} has many options (third optional Hash argument):
  # * +:default+ gives default attribute value. It may be a simple value (an Integer
  #   for an Int attribute, for example) or a lambda,
  # * +:builder+ to give a builder/constructor lambda to create attribute. The lambda
  #   takes 2 arguments: {Struct} subclass object owning attribute, and type class as passes
  #   as second argument to {.define_attr},
  # * +:optional+ to define this attribute as optional. This option takes a lambda
  #   parameter used to say if this attribute is present or not. The lambda takes an argument
  #   ({Struct} subclass object owning attribute),
  # For example:
  #   # 32-bit integer attribute defaulting to 1
  #   define_attr :type, BinStruct::Int32, default: 1
  #   # 16-bit integer attribute, created with a random value. Each instance of this
  #   # object will have a different value.
  #   define_attr :id, BinStruct::Int16, default: ->(obj) { rand(65535) }
  #   # a size attribute
  #   define_attr :body_size, BinStruct::Int16
  #   # String attribute which length is taken from body_size attribute
  #   define_attr :body, BinStruct::String, builder: ->(obj, type) { type.new(length_from: obj[:body_size]) }
  #   # 16-bit enumeration type. As :default not specified, default to first value of enum
  #   define_attr :type_class, BinStruct::Int16Enum, enum: { 'class1' => 1, 'class2' => 2}
  #   # optional attribute. Only present if another attribute has a certain value
  #   define_attr :opt1, BinStruct::Int16, optional: ->(h) { h.type == 42 }
  #
  # == Generating bit attributes
  # {.define_bit_attr} creates a bit attribute. For example, +frag+ attribute in IP header:
  #   define_bit_attr :frag, flag_rsv: 1, flag_df: 1, flag_mf: 1, fragment_offset: 13
  #
  # This example generates methods:
  # * +#frag+ and +#frag=+ to access +frag+ attribute as a 16-bit integer,
  # * +#flag_rsv?+, +#flag_rsv=+, +#flag_df?+, +#flag_df=+, +#flag_mf?+ and +#flag_mf=+
  #   to access Boolean RSV, MF and DF flags from +frag+ attribute,
  # * +#fragment_offset+ and +#fragment_offset=+ to access 13-bit integer fragment
  #   offset subattribute from +frag+ attribute.
  #
  # == Creating a new Struct class from another one
  # Some methods may help in this case:
  # * {.define_attr_before} to define a new attribute before an existing one,
  # * {.define_attr_after} to define a new attribute after an existing onr,
  # * {.remove_attr} to remove an existing attribute,
  # * {.uptade_fied} to change options of an attribute (but not its type),
  #
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class Struct
    # @private
    StructDef = ::Struct.new(:type, :default, :builder, :optional, :options)
    # @private attribute names, ordered as they were declared
    @ordered_attrs = []
    # @private attribute definitions
    @attr_defs = {}
    # @private bit attribute definitions
    @bit_attrs = {}

    # Format to inspect attribute
    FMT_ATTR = "%14s %16s: %s\n"

    class << self
      # Get attribute definitions for this class.
      # @return [Hash]
      attr_reader :attr_defs
      # Get bit attribute defintions for this class
      # @return [Hash{Symbol=>Array[Symbol]}]
      attr_reader :bit_attrs

      # On inheritage, create +@attr_defs+ class variable
      # @param [Class] klass
      # @return [void]
      def inherited(klass)
        super

        attr_defs = {}
        @attr_defs.each do |k, v|
          attr_defs[k] = v.clone
        end
        ordered = @ordered_attrs.clone
        bf = bit_attrs.clone

        klass.class_eval do
          @ordered_attrs = ordered
          @attr_defs = attr_defs
          @bit_attrs = bf
        end
      end

      # Get attribute names
      # @return [Array<Symbol>]
      def attributes
        @ordered_attrs
      end

      # Define an attribute in class
      #   class BinaryStruct < BinStruct::Struct
      #     # 8-bit value
      #     define_attr :value1, BinStruct::Int8
      #     # 16-bit value
      #     define_attr :value2, BinStruct::Int16
      #     # specific class, may use a specific constructor
      #     define_attr :value3, MyClass, builder: ->(obj, type) { type.new(obj) }
      #   end
      #
      #   bs = BinaryStruct.new
      #   bs[value1]   # => BinStruct::Int8
      #   bs.value1    # => Integer
      # @param [Symbol] name attribute name
      # @param [Structable] type class or instance
      # @param [Hash] options Unrecognized options are passed to object builder if
      #   +:builder+ option is not set.
      # @option options [Object] :default default value. May be a proc. This lambda
      #   take one argument: the caller object.
      # @option options [Lambda] :builder lambda to construct this attribute.
      #   Parameters to this lambda is the caller object and the attribute type class.
      # @option options [Lambda] :optional define this attribute as optional. Given lambda
      #   is used to known if this attribute is present or not. Parameter to this lambda is
      #   the being defined Struct object.
      # @return [void]
      def define_attr(name, type, options = {})
        attributes << name
        attr_defs[name] = StructDef.new(type,
                                        options.delete(:default),
                                        options.delete(:builder),
                                        options.delete(:optional),
                                        options)

        add_methods(name, type)
      end

      # Define a attribute, before another one
      # @param [Symbol,nil] other attribute name to create a new one before. If +nil+,
      #    new attribute is appended.
      # @param [Symbol] name attribute name to create
      # @param [Structable] type class or instance
      # @param [Hash] options See {.define_attr}.
      # @return [void]
      # @see .define_attr
      def define_attr_before(other, name, type, options = {})
        define_attr name, type, options
        return if other.nil?

        move_attr(name, before: other)
      end

      # Define an attribute, after another one
      # @param [Symbol,nil] other attribute name to create a new one after. If +nil+,
      #    new attribute is appended.
      # @param [Symbol] name attribute name to create
      # @param [Structable] type class or instance
      # @param [Hash] options See {.define_attr}.
      # @return [void]
      # @see .define_attr
      def define_attr_after(other, name, type, options = {})
        define_attr name, type, options
        return if other.nil?

        move_attr(name, after: other)
      end

      # Remove a previously defined attribute
      # @param [Symbol] name
      # @return [void]
      def remove_attr(name)
        attributes.delete(name)
        attr_def = attr_defs.delete(name)
        undef_method name if method_defined?(name)
        undef_method :"#{name}=" if method_defined?(:"#{name}=")
        return unless bit_attrs[name]

        attr_def.type.new.bit_methods.each { |meth| undef_method(meth) }
      end

      # Update a previously defined attribute
      # @param [Symbol] name attribute name to create
      # @param [Hash] options See {.define_attr}.
      # @return [void]
      # @see .define_attr
      # @raise [ArgumentError] unknown attribute
      def update_attr(name, options)
        check_existence_of(name)

        %i[default builder optional].each do |property|
          attr_defs_property_from(name, property, options)
        end

        attr_defs[name].options.merge!(options)
      end

      # Define a bit attribute on given attribute
      #   class MyHeader < BinStruct::Struct
      #     define_attr :flags, BinStruct::Int16
      #     # define a bit attribute named :flag
      #     # flag1, flag2 and flag3 are 1-bit attributes
      #     # type and stype are 3-bit attributes. reserved is a 7-bit attribute
      #     define_bit_attr :flags, flag1: 1, flag2: 1, flag3: 1, type: 3, stype: 3, reserved: 7
      #   end
      # A bit attribute of size 1 bit defines 3 methods:
      # * +#attr+ which returns an Integer,
      # * +#attr?+ which returns a Boolean,
      # * +#attr=+ which accepts an Integer or a Boolean.
      # A bit attribute of more bits defines only 2 methods:
      # * +#attr+ which returns an Integer,
      # * +#attr=+ which takes an Integer.
      # @param [Symbol] attr attribute name
      #   subclass)
      # @param [:big,:little,:native] endian endianess of Integer
      # @param [Hash{Symbol=>Integer}] fields Hash defining fields. Keys are field names, values are field sizes.
      # @return [void]
      # @since 0.3.0
      def define_bit_attr(attr, endian: :big, **fields)
        width = fields.reduce(0) { |acc, ary| acc + ary.last }
        bit_attr_klass = BitAttr.create(width: width, endian: endian, **fields)
        define_attr(attr, bit_attr_klass)
        fields.each_key { |field| register_bit_attr_field(attr, field) }
        bit_attr_klass.new.bit_methods.each do |meth|
          if meth.to_s.end_with?('=')
            define_method(meth) { |value| self[attr].send(meth, value) }
          else
            define_method(meth) { self[attr].send(meth) }
          end
        end
      end

      # Define a bit attribute, before another attribute
      # @param [Symbol,nil] other attribute name to create a new one before.
      #    If +nil+, new attribute is appended.
      # @param [Symbol] name attribute name to create
      # @param [:big,:little,:native] endian endianess of Integer
      # @param [Hash{Symbol=>Integer}] fields Hash defining fields. Keys are field names, values are field sizes.
      # @return [void]
      # @since 0.3.0
      # @see .define_bit_attr
      def define_bit_attr_before(other, name, endian: :big, **fields)
        define_bit_attr(name, endian: endian, **fields)
        return if other.nil?

        move_attr(name, before: other)
      end

      # Define a bit attribute after another attribute
      # @param [Symbol,nil] other attribute name to create a new one after.
      #    If +nil+, new attribute is appended.
      # @param [Symbol] name attribute name to create
      # @param [:big,:little,:native] endian endianess of Integer
      # @param [Hash{Symbol=>Integer}] fields Hash defining fields. Keys are field names, values are field sizes.
      # @return [void]
      # @since 0.3.0
      # @see .define_bit_attr
      def define_bit_attr_after(other, name, endian: :big, **fields)
        define_bit_attr(name, endian: endian, **fields)
        return if other.nil?

        move_attr(name, after: other)
      end

      private

      # @param [Symbol] name
      # @param [Symbol,nil] before
      # @param [Symbol,nil] after
      # @return [void]
      # @raise [ArgumentError] Both +before+ and +after+ are nil, or both are set.
      def move_attr(name, before: nil, after: nil)
        move_check_destination(before, after)

        other = before || after
        attributes.delete(name)
        idx = attributes.index(other)
        raise ArgumentError, "unknown #{other} attribute" if idx.nil?

        idx += 1 unless after.nil?
        attributes[idx, 0] = name
      end

      def move_check_destination(before, after)
        raise ArgumentError 'one of before: and after: arguments MUST be set' if before.nil? && after.nil?
        raise ArgumentError 'only one of before and after argument MUST be set' if !before.nil? && !after.nil?
      end

      def add_methods(name, type)
        define = []
        if type < Enum
          define << "def #{name}; self[:#{name}].to_i; end"
          define << "def #{name}=(val) self[:#{name}].value = val; end"
        else
          define << "def #{name}\n  " \
                    "to_and_from_human?(:#{name}) ? self[:#{name}].to_human : self[:#{name}]\n" \
                    'end'
          define << "def #{name}=(val)\n  " \
                    "to_and_from_human?(:#{name}) ? self[:#{name}].from_human(val) : self[:#{name}].read(val)\n" \
                    'end'
        end

        define.delete_at(1) if instance_methods.include?(:"#{name}=")
        define.delete_at(0) if instance_methods.include?(name)
        class_eval define.join("\n")
      end

      def register_bit_attr_field(attr, field)
        bit_attrs[attr] ||= []
        bit_attrs[attr] << field
      end

      def attr_defs_property_from(attr, property, options)
        attr_defs[attr].send(:"#{property}=", options.delete(property)) if options.key?(property)
      end

      def check_existence_of(attr)
        raise ArgumentError, "unknown #{attr} attribute for #{self}" unless attr_defs.key?(attr)
      end
    end

    # Create a new Struct object
    # @param [Hash] options Keys are symbols. They should have name of object
    #   attributes, as defined by {.define_attr} and by {.define_bit_attr}.
    def initialize(options = {})
      @attributes = {}
      @optional_attributes = {}

      self.class.attributes.each do |attr|
        build_attribute(attr)
        initialize_value(attr, options[attr])
        initialize_optional(attr)
      end

      self.class.bit_attrs.each_value do |bit_fields|
        bit_fields.each do |bit|
          send(:"#{bit}=", options[bit]) if options[bit]
        end
      end
    end

    # Get attribute object
    # @param [Symbol] attr attribute name
    # @return [Structable]
    def [](attr)
      @attributes[attr]
    end

    # Set attribute object
    # @param [Symbol] attr attribute name
    # @param [Object] obj
    # @return [Object]
    def []=(attr, obj)
      @attributes[attr] = obj
    end

    # Get all attribute names
    # @return [Array<Symbol>]
    def attributes
      self.class.attributes
    end

    # Get all optional attribute names
    # @return[Array<Symbol>,nil]
    def optional_attributes
      @optional_attributes.keys
    end

    # Say if this attribue is optional
    # @param [Symbol] attr attribute name
    # @return [Boolean]
    def optional?(attr)
      @optional_attributes.key?(attr)
    end

    # Say if an optional attribute is present
    # @return [Boolean]
    def present?(attr)
      return true unless optional?(attr)

      @optional_attributes[attr].call(self)
    end

    # Populate object from a binary string
    # @param [String] str
    # @return [Struct] self
    def read(str)
      return self if str.nil?

      force_binary(str)
      start = 0
      attributes.each do |attr|
        next unless present?(attr)

        obj = self[attr].read(str[start..])
        start += self[attr].sz
        self[attr] = obj unless obj == self[attr]
      end

      self
    end

    # Common inspect method for structs.
    #
    # A block may be given to differently format some attributes. This
    # may be used by subclasses to handle specific attributes.
    # @yieldparam attr [Symbol] attribute to inspect
    # @yieldreturn [String,nil] the string to print for +attr+, or +nil+
    #  to let +inspect+ generate it
    # @return [String]
    def inspect
      str = inspect_titleize
      attributes.each do |attr|
        next if attr == :body
        next unless present?(attr)

        result = yield(attr) if block_given?
        str << (result || inspect_attribute(attr, self[attr], 1))
      end
      str
    end

    # Return object as a binary string
    # @return [String]
    def to_s
      attributes.select { |attr| present?(attr) }
                .map! { |attr| force_binary @attributes[attr].to_s }.join
    end

    # Size of object as binary string
    # @return [nteger]
    def sz
      to_s.size
    end

    # Return object as a hash
    # @return [Hash] keys: attributes, values: attribute values
    def to_h
      attributes.to_h { |attr| [attr, @attributes[attr].to_human] }
    end

    # Get offset of given attribute in {Struct}.
    # @param [Symbol] attr attribute name
    # @return [Integer]
    # @raise [ArgumentError] unknown attribute
    def offset_of(attr)
      raise ArgumentError, "#{attr} is an unknown attribute of #{self.class}" unless @attributes.include?(attr)

      offset = 0
      attributes.each do |a|
        break offset if a == attr
        next unless present?(a)

        offset += self[a].sz
      end
    end

    # Get bit attributes definition for given attribute.
    # @param [Symbol] attr attribute defining bit attributes
    # @return [Hash,nil] keys: bit attributes, values: their size in bits
    def bits_on(attr)
      self.class.bit_attrs[attr]
    end

    private

    # Deeply duplicate +@attributes+
    # @return [void]
    def initialize_copy(_other)
      attributes = {}
      @attributes.each { |k, v| attributes[k] = v.dup }
      @attributes = attributes
    end

    # Force str to binary encoding
    # @param [String] str
    # @return [String]
    def force_binary(str)
      BinStruct.force_binary(str)
    end

    # @param [Symbol] attr attribute name
    # @return [Boolean] +true= if #from_human and #to_human are both defined for given attribute
    def to_and_from_human?(attr)
      self[attr].respond_to?(:to_human) && self[attr].respond_to?(:from_human)
    end

    def attr_defs
      self.class.attr_defs
    end

    # rubocop:disable Metrics/AbcSize
    def build_attribute(attr)
      type = attr_defs[attr].type

      @attributes[attr] = if attr_defs[attr].builder
                            attr_defs[attr].builder.call(self, type)
                          elsif !attr_defs[attr].options.empty?
                            type.new(attr_defs[attr].options)
                          else
                            type.new
                          end
    end
    # rubocop:enable Metrics/AbcSize

    def initialize_value(attr, val)
      type = attr_defs[attr].type
      default = attr_defs[attr].default
      default = default.to_proc.call(self) if default.is_a?(Proc)

      value = val || default
      if value.class <= type
        @attributes[attr] = value
      elsif @attributes[attr].respond_to?(:from_human)
        @attributes[attr].from_human(value)
      else
        @attributes[attr].read(value)
      end
    end

    # @param [Symbol] attr
    # @return [void]
    def initialize_optional(attr)
      optional = attr_defs[attr].optional
      @optional_attributes[attr] = optional if optional
    end

    # @return [String]
    def inspect_titleize
      title = self.class.to_s
      +"-- #{title} #{'-' * (66 - title.length)}\n"
    end

    # @param [:Symbol] attr
    # @param [Structable] value
    # @param [Integer] level
    # @return [::String]
    def inspect_attribute(attr, value, level = 1)
      str = inspect_shift_level(level)
      value_lines = value.format_inspect.split("\n")
      str << (FMT_ATTR % [value.type_name, attr, value_lines.shift])
      return str if value_lines.empty?

      shift = (FMT_ATTR % ['', '', 'START']).index('START')
      value_lines.each do |l|
        str << inspect_shift_level(level)
        str << (' ' * shift) << l << "\n"
      end
      str
    end

    # @param [Integer] level
    # @return [String]
    def inspect_shift_level(level = 1)
      '  ' * (level + 1)
    end
  end
end

# rubocop:enable Metrics/ClassLength
