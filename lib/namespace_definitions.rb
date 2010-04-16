module SData
  class Namespace
    #TODO: yaml file is probably better for the definitions
    @@sdata_schemas = { 
                           "crmErp"     => "http://schemas.sage.com/crmErp",
                           "http"       => "http://schemas.sage.com/sdata/http/2008/1",
                           "opensearch" => "http://a9.com/-/spec/opensearch/1.1",
                           "sdata"      => "http://schemas.sage.com/sdata/2008/1",
                           "sle"        => "http://www.microsoft.com/schemas/rss/core/2005",
                           "xsi"        => "http://www.w3.org/2001/XMLSchema-instance"
                         }
                         
    def self.sdata_schemas
      @@sdata_schemas
    end
    
    def self.add_feed_extension_namespaces(namespaces)
      namespaces.each do |namespace|
         Atom::Feed.add_extension_namespace(namespace.to_s, @@sdata_schemas[namespace.to_s])
      end
    end

  end
end

#some experimenting I was doing to try and get the Atom::Xml::NamespaceMap to be populated with our values
#couldn't get it to work right anyways... Daniel, maybe you'll have better luck
module SData
  module NamespaceMapMixin
    def self.included(base) 
      base.class_eval do 
        alias_method :initialize, :initialize_with_map
      end
    end

    def initialize_with_map(default=Atom::NAMESPACE)
        @default = default
        @i = 0
        @map = SData::Namespace.sdata_schemas.invert
    end
  end
end
Atom::Xml::NamespaceMap.__send__ :include, SData::NamespaceMapMixin