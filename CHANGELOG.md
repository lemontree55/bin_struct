# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.3.0 - 2024-12-02

### Added

- `BitAddr` class is added. This class is used as a `Structable` type to handle bitfield attributes.
- Add `Struct.define_bit_attr`, `.define_bit_attr_before` and `.define_bit_attr_before` to define bitfield attributes.

### Changed

- `Struct.define_bit_attr_on` is removed in favor of `Struct.define_bit_attr`. Bitfield attributes are now first class attributes, and no more an onverlay on `Int`.

## 0.2.1 - 2024-11-25

### Added

- `CString` and `String` initializers now accepts `:value` option to set string initial value.

### Changed

- `IntString` initializer option `:string` is renamed into `:value`.

## 0.2.0 - 2024-07-21

### Changed

- `BinStruct::Fields` renamed into `BinStruct::Struct`, and `*field*` methods are renamed into `*attr*` or `*attributes*`.
- `BinStruct::Struct#inspect`: add a title line.

### Fixed

- Fix `BinStruct::ArrayOfInt#read_from_array` by using `value:` option.
- Fix `BinStruct::IntString#calc_length` by using `#from_human` instead of `#read`.
- `BinStruct::String#to_s`: force binary encoding.
- `BinStruct::String#<<`: force binary encoding on argument before catenating.

## 0.1.0 - 2024-07-13

- Initial release
