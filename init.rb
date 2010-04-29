require 'active_support'
require 'action_controller'
require 'atom' # TODO: add ratom _dependency_

#needed to be defined for each app and contract. refactor if more than 1 contract is supported.

$SDATA_SCOPE = "@user"
$SDATA_SCHEMAS = { 
                   "crmErp"     => "http://schemas.sage.com/crmErp",
                   "http"       => "http://schemas.sage.com/sdata/http/2008/1",
                   "opensearch" => "http://a9.com/-/spec/opensearch/1.1",
                   "sdata"      => "http://schemas.sage.com/sdata/2008/1",
                   "sle"        => "http://www.microsoft.com/schemas/rss/core/2005",
                   "xsi"        => "http://www.w3.org/2001/XMLSchema-instance"
                 }

__DIR__ = File.dirname(__FILE__)
Dir.glob(File.join(__DIR__, 'lib', '**', '*.rb')) { |filename| require filename }