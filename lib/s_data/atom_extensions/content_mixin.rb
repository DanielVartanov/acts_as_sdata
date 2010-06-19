module SData
  module AtomExtensions
    module  ContentMixin
      class Diagnosis < Atom::Content::Base
        attribute :type, :'xml:lang'
        def to_xml(*params)
          self[0] #magic done in diagnosis.rb
        end
      end
      
    end
  end
end
Atom::Content.__send__ :include, SData::AtomExtensions::ContentMixin