# frozen_string_literal: true

# This file is part of BinStruct
# see https://github.com/lemontree55/bin_struct for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

require 'forwardable'

module BinStruct
  # @abstract Base class to define set of {Structable} subclasses.
  #
  # This class mimics regular Ruby Array, but it is {Structable} and responds to {LengthFrom}.
  #
  # Concrete subclasses may define 2 private methods:
  #
  # == #record_from_hash
  # This method
  # is called by {#push} and {#<<} to add an object to the set.
  #
  # A default method is defined by {Array}: it calls constructor of class defined
  # by {.set_of}.
  #
  # == #real_type
  # Subclasses should define private method +#real_type+ if {.set_of} type
  # may be subclassed. This method should return real class to use. It
  # takes an only argument, which is of type given by {.set_of}.
  #
  # Default behaviour of this method is to return argument's class.
  #
  # @author Sylvain Daubert (2016-2024)
  # @author LemonTree55
  class Array
    extend Forwardable
    include Enumerable
    include Structable
    include LengthFrom

    # @!method [](index)
    #   Return the element at +index+.
    #   @param [Integer] index
    #   @return [Object]
    # @!method clear
    #   Clear array.
    #   @return [void]
    #   @see #clear!
    # @!method each
    #   Calls the given block once for each element in self, passing that
    #   element as a parameter. Returns the array itself, or an enumerator if no block is given.
    #   @return [::Array, Enumerator]
    # @method empty?
    #   Return +true+ if contains no element.
    #   @return [Boolean]
    # @!method first
    #   Return first element
    #   @return [Object]
    # @!method last
    #   Return last element.
    #   @return [Object]
    # @!method size
    #   Get number of element in array
    #   @return [Integer]
    def_delegators :@array, :[], :clear, :each, :empty?, :first, :last, :size
    alias length size

    # Separator used in {#to_human}.
    # May be overriden by subclasses
    HUMAN_SEPARATOR = ','

    # rubocop:disable Naming/AccessorMethodName
    class << self
      # Get class set with {.set_of}.
      # @return [Class]
      def set_of_klass
        @klass
      end

      # Define type of objects in set. Used by {#read} and {#push}.
      # @param [Class] klass
      # @return [void]
      def set_of(klass)
        @klass = klass
      end
    end
    # rubocop:enable Naming/AccessorMethodName

    # @param [Hash] options
    # @option options [Int] counter Int object used as a counter for this set
    # @example counter example
    #   # Define a counter
    #   counter = BinStruct::Int8.new
    #   counter.to_i # => 0
    #
    #   # Define an array with associated counter
    #   ary = BinStruct::ArrayOfInt8.new(counter: counter)
    #   # Add 2 elements to arry, increment counter twice
    #   ary.read([1, 2])
    #   counter.to_i #=> 2
    #   # Add a third element
    #   ary << BinStruct::Int8.new(value: 42)
    #   counter.to_i #=> 3
    #
    #   # push does not increment the counter
    #   ary.push(BinStruct::Int8.new(value: 100))
    #   counter.to_i #=> 3
    def initialize(options = {})
      @counter = options[:counter]
      @array = []
      initialize_length_from(options)
    end

    # Initialize array for copy:
    # * duplicate internal array.
    # @note Associated counter, if any, is not duplicated
    def initialize_copy(_other)
      @array = @array.dup
    end

    # Check equality. Equality is checked on underlying array.
    # @return [Boolean]
    def ==(other)
      @array == case other
                when Array
                  other.to_a
                else
                  other
                end
    end

    # Clear array. Reset associated counter, if any.
    # @return [void]
    # @see #clear
    def clear!
      @array.clear
      @counter&.from_human(0)
    end

    # Delete an object from this array. Update associated counter if any
    # @param [Object] obj
    # @return [Object] deleted object
    def delete(obj)
      deleted = @array.delete(obj)
      @counter.from_human(@counter.to_i - 1) if @counter && deleted
      deleted
    end

    # Delete element at +index+. Update associated counter if any
    # @param [Integer] index
    # @return [Object,nil] deleted object
    def delete_at(index)
      deleted = @array.delete_at(index)
      @counter.from_human(@counter.to_i - 1) if @counter && deleted
      deleted
    end

    # @abstract depend on private method +#record_from_hash+ which should be
    #   declared by subclasses.
    # Add an object to this array. Do not update associated counter. If associated must be incremented, use
    # {#<<}
    # @param [Object] obj type depends on subclass
    # @return [self]
    # @see #<<
    def push(obj)
      obj = case obj
            when Hash
              record_from_hash(obj)
            else
              obj
            end
      @array << obj
      self
    end

    # @abstract depend on private method +#record_from_hash+ which should be
    #   declared by subclasses.
    # Add an object to this array, and increment associated counter, if any. If associated counter must not be
    # incremented, use {#push}.
    # @param [Object] obj type depends on subclass
    # @return [self]
    # @see #push
    def <<(obj)
      push(obj)
      @counter&.from_human(@counter.to_i + 1)
      self
    end

    # Populate object from a string or from an array of hashes
    # @param [::String, ::Array<Hash>] data
    # @return [self]
    def read(data)
      clear
      case data
      when ::Array
        read_from_array(data)
      else
        read_from_string(data)
      end
      self
    end

    # Get size in bytes
    # @return [Integer]
    def sz
      to_s.size
    end

    # Return underlying Ruby Array
    # @return [::Array]
    def to_a
      @array
    end

    # Get binary string
    # @return [::String]
    def to_s
      @array.map(&:to_s).join
    end

    # Get a human readable string
    # @return [::String]
    def to_human
      @array.map(&:to_human).join(self.class::HUMAN_SEPARATOR)
    end

    private

    # rubocop:disable Metrics/CyclomaticComplexity

    def read_from_string(str)
      return self if str.nil? || @counter&.to_i&.zero?

      str = read_with_length_from(str)
      until str.empty? || (@counter && size == @counter.to_i)
        obj = create_object_from_str(str)
        @array << obj
        str.slice!(0, obj.sz)
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def read_from_array(ary)
      return self if ary.empty?

      ary.each do |hsh|
        self << hsh
      end
    end

    def record_from_hash(hsh)
      obj_klass = self.class.set_of_klass
      unless obj_klass
        raise NotImplementedError,
              'class should define #record_from_hash or declare type of elements in set with .set_of'
      end

      obj = obj_klass.new(hsh) if obj_klass
      klass = real_type(obj)
      klass == obj_klass ? obj : klass.new(hsh)
    end

    def real_type(_obj)
      self.class.set_of_klass
    end

    def create_object_from_str(str)
      klass = self.class.set_of_klass
      obj = klass.new.read(str)
      real_klass = real_type(obj)

      if real_klass == klass
        obj
      else
        real_klass.new.read(str)
      end
    end
  end

  # @private
  module ArrayOfIntMixin
    def read_from_array(ary)
      return self if ary.empty?

      ary.each do |i|
        self << self.class.set_of_klass.new(value: i)
      end
    end
  end

  # Specialized {Array} to handle serie of {Int8}.
  # @example
  #   ary = BinStruct::ArrayOfInt8.new
  #   ary.read([0, 1, 2])
  #   ary.to_s #=> "\x00\x01\x02".b
  #
  #   ary.read("\x05\x06")
  #   ary.map(&:to_i) #=> [5, 6]
  class ArrayOfInt8 < Array
    include ArrayOfIntMixin
    set_of Int8
  end

  # Specialized {Array} to handle serie of {Int16}.
  # @example
  #   ary = BinStruct::ArrayOfInt16.new
  #   ary.read([0, 1, 2])
  #   ary.to_s #=> "\x00\x00\x00\x01\x00\x02".b
  #
  #   ary.read("\x05\x06")
  #   ary.map(&:to_i) #=> [0x0506]
  class ArrayOfInt16 < Array
    include ArrayOfIntMixin
    set_of Int16
  end

  # Specialized {Array} to handle serie of {Int16le}.
  # @example
  #   ary = BinStruct::ArrayOfInt16le.new
  #   ary.read([0, 1, 2])
  #   ary.to_s #=> "\x00\x00\x01\x00\x02\x00".b
  #
  #   ary.read("\x05\x06")
  #   ary.map(&:to_i) #=> [0x0605]
  class ArrayOfInt16le < Array
    include ArrayOfIntMixin
    set_of Int16le
  end

  # Specialized {Array} to handle serie of {Int32}.
  # @example
  #   ary = BinStruct::ArrayOfInt32.new
  #   ary.read([0, 1, 2])
  #   ary.to_s #=> "\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x02".b
  #
  #   ary.read("\x00\x00\x05\x06")
  #   ary.map(&:to_i) #=> [0x00000506]
  class ArrayOfInt32 < BinStruct::Array
    include ArrayOfIntMixin
    set_of Int32
  end

  # Specialized {Array} to handle serie of {Int32le}.
  # @example
  #   ary = BinStruct::ArrayOfInt32le.new
  #   ary.read([0, 1, 2])
  #   ary.to_s #=> "\x00\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00".b
  #
  #   ary.read("\x00\x00\x05\x06")
  #   ary.map(&:to_i) #=> [0x06050000]
  class ArrayOfInt32le < BinStruct::Array
    include ArrayOfIntMixin
    set_of Int32le
  end
end
