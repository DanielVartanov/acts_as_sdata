# the following should stay together, to ensure that when adding custom nodes, the namespcaes
# they are in are available to ratom, or it will silently decide to make the node an Atom::Content
SData.config[:schemas].each do |prefix, namespace|
  Atom::Feed.add_extension_namespace(prefix.to_s, namespace)
  Atom::Entry.add_extension_namespace(prefix.to_s, namespace)
end


Atom::Entry.element "sdata:payload", 
                    :class => SData::AtomExtensions::Nodes::Payload,
                    :namespace => SData.config[:schemas][:sdata]

#TODO the rest should be done like payload
Atom::Entry.element :diagnosis, :class => Atom::Content

Atom::Entry.element "sync:syncState",
                    :class => SData::AtomExtensions::Nodes::SyncState,
                    :namespace => SData.config[:schemas][:sync]
Atom::Feed.element  "sync:digest", 
                    :class => SData::AtomExtensions::Nodes::Digest, 
                    :namespace => SData.config[:schemas][:sync]

module Atom
  class Entry
    def extended_element(element_with_namespace)
      namespace, element = element_with_namespace.split(':')
      self.simple_extensions.keys.each do |key|
        return self.simple_extensions[key][0] if key == "{#{SData.config[:schemas][namespace]},#{element}}"
      end
      nil
    end

    def to_attributes
      attributes = {}
      self['http://sdata.sage.com/schemes/attributes'].each_pair do |name, values|
        attributes[name] = values.first
      end
      attributes
    end
  end
end