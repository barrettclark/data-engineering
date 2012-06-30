ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.require
require 'test/unit'
require 'rack/test'

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
