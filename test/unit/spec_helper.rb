
def setup_active_record
  ActiveRecord::Base.establish_connection :adapter => "sqlite3",
    :database  => ":memory:"
end

require 'atom'
require 'active_record'
require 'action_pack'
require 'webrat'

include Webrat::Matchers

setup_active_record

__DIR__ =File.dirname(__FILE__)
require File.expand_path(File.join(__DIR__, 'class_stubs', 'payload'))
require File.expand_path(File.join(__DIR__, '..', '..', 'init'))