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

Dir[File.join(File.dirname(__FILE__), 'spec_helpers', '**', '*.rb')].each { |helper| require helper }

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
__DIR__ = File.dirname(__FILE__)
require File.expand_path(File.join(__DIR__, '..', 'init'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'model_base'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'user'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'customer'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'contact'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'address'))
require File.expand_path(File.join(__DIR__, 'class_stubs', 'sd_uuid'))

SData.reset!
SData.config = {:base_url => 'http://www.example.com', 
                               :application => 'example', 
                               :contract_namespace => 'SData::Contracts',
                               :contracts => ['myContract'],
                               :defaultContract => ['myContract'],
                               :schemas => {
                                 "xs"         => "http://www.w3.org/2001/XMLSchema",
                                 "cf"         => "http://www.microsoft.com/schemas/rss/core/2005",
                                 "sme"        => "http://schemas.sage.com/sdata/sme/2007",
                                 "sc"         => "http://schemas.sage.com/sc/2009",
                                 "crmErp"     => "http://schemas.sage.com/crmErp/2008",
                                 "http"       => "http://schemas.sage.com/sdata/http/2008/1",
                                 "sync"       => "http://schemas.sage.com/sdata/sync/2008/1",
                                 "opensearch" => "http://a9.com/-/spec/opensearch/1.1/",
                                 "sdata"      => "http://schemas.sage.com/sdata/2008/1",
                                 "xsi"        => "http://www.w3.org/2001/XMLSchema-instance",
                                 "sle"        => "http://www.microsoft.com/schemas/rss/core/2005",
                                 "bb"         => "http://www.billingboss.com/schemas/sdata"
                               },
                               :show_stack_trace => true}
