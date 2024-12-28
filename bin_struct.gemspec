# frozen_string_literal: true

require_relative 'lib/bin_struct/version'

Gem::Specification.new do |spec|
  spec.name = 'bin_struct'
  spec.version = BinStruct::VERSION
  spec.authors = ['LemonTree55']
  spec.email = ['lenontree@proton.me']

  spec.summary = 'Binary dissector and generator'
  spec.description = <<~DESC
    BinStruct is a binary dissector and generator. It eases manipulating complex binary data.
  DESC
  spec.homepage = 'https://github.com/lemontree55/bin_struct'
  spec.license = 'MIT'
  # Ruby 3.0
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/lemontree55/bin_struct'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/lemontree55/bin_struct/issues'

  spec.files = Dir['lib/**/**'] << 'CHANGELOG.md'
  # spec.bindir = 'exe'
  # spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.extra_rdoc_files = Dir['README.md', 'LICENSE']
  spec.rdoc_options += [
    '--title', 'BinStruct',
    '--main', 'README.md',
    '--inline-source',
    '--quiet'
  ]
end
