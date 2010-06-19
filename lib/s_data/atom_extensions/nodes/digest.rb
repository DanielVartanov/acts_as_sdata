module SData
  module AtomExtensions
    module Nodes

      class DigestEntry
        include Atom::Xml::Parseable
        add_extension_namespace "sdata", SData.config[:schemas][:sdata]
        add_extension_namespace 'sync', SData.config[:schemas][:sync]
        element "sync:endpoint", :namespace => SData.config[:schemas][:sync]
        element "sync:tick", :namespace => SData.config[:schemas][:sync]
        element "sync:stamp", :namespace => SData.config[:schemas][:sync]
        element "sync:conflictPriority", :namespace => SData.config[:schemas][:sync]
        
        def initialize(xml=nil)
          if xml
            # puts "DigestEntry call xml.read"
            xml.read
            parse(xml)
          end
        end
        
        def self.parse(xml)
          new(xml)
        end
      end

      class Digest
        include Atom::Xml::Parseable
        add_extension_namespace "sdata", SData.config[:schemas][:sdata]
        add_extension_namespace 'sync', SData.config[:schemas][:sync]
        elements "sync:digestEntry", :class => SData::AtomExtensions::Nodes::DigestEntry, :namespace => SData.config[:schemas][:sync]
        uri_attribute "sdata:url"
        element "sync:origin", :namespace => SData.config[:schemas][:sync]
        
        def initialize(xml=nil)
          xml.read
          parse(xml)
        end
        
        def self.parse(xml)
          new(xml)
        end
      end


    end
  end
end