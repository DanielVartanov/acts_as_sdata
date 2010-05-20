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

#needed for tests only
$APPLICATION_HOST = "www.example.com"
$APPLICATION_URL = "http://" + $APPLICATION_HOST
$SDATA_STORE_PATH = "/sdata/example/myContract/-/"


__DIR__ =File.dirname(__FILE__)
require File.expand_path(File.join(__DIR__, 'class_stubs', 'model_base'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'user'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'customer'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'contact'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'address'))
require File.expand_path(File.join(__DIR__, '..', '..', 'init'))
