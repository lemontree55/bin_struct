# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new do |task|
  task.patterns = ['lib/**/*.rb']
end

require 'yard'
require 'yard/doctest/rake'

YARD::Rake::YardocTask.new do |t|
  t.options = ['--no-private']
end
YARD::Doctest::RakeTask.new

task default: %i[spec rubocop]
