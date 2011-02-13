require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

task :default => [:test]

desc "Run tests"
Rake::TestTask.new("test") { |t|
  t.pattern = 'test/test_*.rb'
  t.verbose = true
  t.warning = true
}