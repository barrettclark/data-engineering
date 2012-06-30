ENV['RACK_ENV'] ||= 'development'

require 'rake'
require 'rake/testtask'
require 'bundler/setup'
Bundler.require

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/*test.rb']
  t.verbose = true
end

desc "rake test is the default action."
task :default => :test
