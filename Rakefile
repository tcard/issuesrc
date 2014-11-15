require 'rspec/core/rake_task'
require 'bundler/gem_tasks'
require 'yard'

# Default directory to look in is `/specs`
# Run with `rake spec`
RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ['--color']
end

YARD::Rake::YardocTask.new do |t|
end

task :default => :spec
