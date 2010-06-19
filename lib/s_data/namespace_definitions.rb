# The following pre-sets the namespace prefix for simple extensions. It is done this way because
# the namespace map is lazily created in the Atom::Feed.to_xml method. Could also alias to_xml,
# and add all the namespaces in extensions_namespaces to this map
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
        @map = SData.config[:schemas].invert
    end
  end
end
Atom::Xml::NamespaceMap.__send__ :include, SData::NamespaceMapMixin