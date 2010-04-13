module SData
  module AtomContentMixin
    class Payload < Atom::Content::Base
      XHTML = 'http://www.w3.org/1999/xhtml'      
      attribute :type, :'xml:lang'
      
      def initialize(o)
        case o
        when String
          super(o)
          @type = "xhtml"
        when XML::Reader
          super("")   
          xml = o
          parse(xml, :once => true)
          starting_depth = xml.depth

          # Get the next element - should be a div according to the atom spec
          while xml.read && xml.node_type != XML::Reader::TYPE_ELEMENT; end        

          if xml.local_name == 'payload' && xml.namespace_uri == XHTML        
            set_content(xml.read_inner_xml.strip.gsub(/\s+/, ' '))
          else
            set_content(xml.read_outer_xml)
          end

          # get back to the end of the element we were created with
          while xml.read == 1 && xml.depth > starting_depth; end          
        end
      end
      
      def to_xml(nodeonly = true, name = 'payload', namespace = nil, namespace_map = Atom::Xml::NamespaceMap.new)
        node = XML::Node.new("sdata:payload")
        p = XML::Parser.string(to_s)
        content = p.parse.root.copy(true)
        node << content
        node
      end
      
    end
  end
end
Atom::Content.__send__ :include, SData::AtomContentMixin