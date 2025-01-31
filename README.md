[![Gem Version](https://badge.fury.io/rb/bin_struct.svg)](https://badge.fury.io/rb/bin_struct)
[![Specs](https://github.com/lemontree55/bin_struct/actions/workflows/main.yml/badge.svg)](https://github.com/lemontree55/bin_struct/actions/workflows/main.yml)

# BinStruct

BinStruct provides a simple way to create and dissect binary data. It is an extraction from [PacketGen](https://github.com/lemontree55/packetgen) 3.x Fields.

## Installation

Installation using RubyGems is easy:

```shell
gem install bin_struct
```

Or add it to a Gemfile:

```ruby
gem 'bin_struct'
```

## Usage

### Create a struct

To create a BinStruct, create a new class inheriting from `BinStruct::Struct`. Then, defines struct attributes using `.define_attr`. `.define_bit_attr` may also be used to define bit field attributes.

```ruby
require 'bin_struct'

class IPHeader < BinStruct::Struct
  # Define a bir field, defaulting to 0x45, and splitted in 2 sub-fields: version and ihl,
  # 4-bit size each
  define_bit_attr :u8, default: 0x45, version: 4, ihl: 4
  # Define a 8-bit unsigned integer named tos
  #  1st argument: a symbol to define attribute name
  #  2nd argument: a class to define attribute type. May be a type provided by BinStruct,
  #                or a user-defined class inheriting from one of these classes
  #  others arguments: options. Here, :default defines a default value for the attribute.
  define_attr :tos, BinStruct::Int8, default: 0
  # Define a 16-bit unsigned integer named length. Default to 20.
  define_attr :length, BinStruct::Int16, default: 20
  # Define a 16-bir unsigned integer named id. It is initialized with a random number
  define_attr :id, BinStruct::Int16, default: ->(_) { rand(65_535) }
  # Define a bit field composed of 4 subfields of 1, 1, 1 and 13 bit, respectively
  define_bit_attr :frag, flag_rsv: 1, flag_df: 1, flag_mf: 1, fragment_offset: 13
  # Define TTL field, a 8-bit unsigned integer, default to 64
  define_attr :ttl, BinStruct::Int8, default: 64
  # Define protocol field (8-bit unsigned integer)
  define_attr :protocol, BinStruct::Int8
  # Define checksum field (16-bit unsigned integer), default to 0
  define_attr :checksum, BinStruct::Int16, default: 0
  # Source and destination addresses, defined as array of 4 8-bit unsigned integers
  define_attr :src, BinStruct::ArrayOfInt8, length_from: -> { 4 }
  define_attr :dst, BinStruct::ArrayOfInt8, length_from: -> { 4 }
end
```

### Parse a binary string

```ruby
# Initialize struct from a binary string
ip = IPHeader.new.read("\x45\x00\x00\x14\x43\x21\x00\x00\x40\x01\x00\x00\x7f\x00\x00\x01\x7f\x00\x00\x01".b)

# Access some fields
p ip.version     #=> 4
p ip.ihl         #=> 5
p ip.id.to_s(16) #=> "4321"
p ip.protocol    #=> 1
p ip.src.map { |byte| byte.to_i }.join('.') #=> "127.0.0.1"
```

```text
> p IPHeader.new.read("\x45\x00\x00\x14\x43\x21\x00\x00\x40\x01\x00\x00\x7f\x00\x00\x01\x7f\x00\x00\x01")
-- IPHeader -----------------------------------------------------------
          BitAttr8               u8: 69               (0x45)
                                     version:4 ihl:5
              Int8              tos: 0                (0x00)
             Int16           length: 20               (0x0014)
             Int16               id: 17185            (0x4321)
         BitAttr16             frag: 0                (0x0000)
                                     flag_rsv:0 flag_df:0 flag_mf:0 fragment_offset:0
              Int8              ttl: 64               (0x40)
              Int8         protocol: 1                (0x01)
             Int16         checksum: 0                (0x0000)
       ArrayOfInt8              src: 127,0,0,1
       ArrayOfInt8              dst: 127,0,0,1

```

### Generate a binary string

```ruby
# Create a new struct with some fields initialized
ip = IPHeader.new(tos: 42, id: 0x1234)

# Initialize fields after creation
ip.src = [192, 168, 1, 1]
ip.dst = [192, 168, 1, 2]

# Generate binary string
ip.to_s
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
