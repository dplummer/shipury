require 'rubygems'
require 'bundler/setup'

require 'setup/active_record'
ENV['RAILS_ENV'] = 'test'

$:.unshift(File.dirname(__FILE__) + '/../lib')

Bundle.require(:test)

require 'logger'
ActiveRecord::Base.logger = Logger.new('/tmp/shipury.log')

require 'shipury'
