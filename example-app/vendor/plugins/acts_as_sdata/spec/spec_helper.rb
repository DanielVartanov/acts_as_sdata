__DIR__ =File.dirname(__FILE__)

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.join(__DIR__, '..', '..', '..', '..')
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))

require File.expand_path(File.join(__DIR__, '..', 'init'))