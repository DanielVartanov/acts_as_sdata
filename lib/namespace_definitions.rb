module SData
  class Namespace
    #TODO: yaml file is probably better for the definitions
    @@sdata_schemas = { 
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
#some experimenting I was doing to try and get the Atom::Xml::NamespaceMap to be populated with our values
#couldn't get it to work right anyways... Daniel, maybe you'll have better luck
#    def self.namespace_map
#      map = Atom::Xml::NamespaceMap.new("http://www.w3.org/2005/Atom")
#      map.set_map(@@sdata_schemas.invert)
#      map
#    end
  end
end
#see line 19 comment
#module SData
#  module NamespaceMapMixin
#    def set_map(map)
#      @map = map
#    end
#  end
#end
#Atom::Xml::NamespaceMap.__send__ :include, SData::NamespaceMapMixin