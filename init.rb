require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

$:.unshift(File.dirname(__FILE__) + '/lib')
require 'shipury'
