
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

$APPLICATION_HOST = "www.example.com"
$APPLICATION_URL = "http://" + $APPLICATION_HOST
$SDATA_STORE_PATH = "/sdata/example/myContract/-/"

$SDATA_SCHEMAS = { 
                   "crmErp"     => "http://schemas.sage.com/crmErp",
                   "http"       => "http://schemas.sage.com/sdata/http/2008/1",
                   "opensearch" => "http://a9.com/-/spec/opensearch/1.1",
                   "sdata"      => "http://schemas.sage.com/sdata/2008/1",
                   "sle"        => "http://www.microsoft.com/schemas/rss/core/2005",
                   "xsi"        => "http://www.w3.org/2001/XMLSchema-instance"
                 }

__DIR__ =File.dirname(__FILE__)
require File.expand_path(File.join(__DIR__, 'class_stubs', 'payload'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'model_base'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'user'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'customer'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'contact'))
require File.expand_path(File.join(__DIR__, '..', '..', 'init'))
