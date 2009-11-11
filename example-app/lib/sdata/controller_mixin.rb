module SData
  module ControllerMixin
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_sdata(options)
        cattr_accessor :sdata_options
        self.sdata_options = options
      end
    end

    module Actions
      def sdata_instance
        instance = self.class.sdata_options[:model].find_by_sdata_instance_id(params[:instance_id])
        render :xml => instance.to_atom, :content_type => "application/atom+xml; type=entry"
      end

      def sdata_collection
        collection = build_sdata_feed
        collection.entries += sdata_scope.map(&:to_atom)

        render :xml => collection, :content_type => "application/atom+xml; type=feed"
      end
    end

    module AuxilliaryMethods
      protected

      def build_sdata_feed
        Atom::Feed.new do |f|
          f.title = sdata_options[:feed][:title]
          f.links << Atom::Link.new(:href => 'http://example.com' + sdata_options[:feed][:path])
          f.updated = Time.now
          f.authors << Atom::Person.new(:name => sdata_options[:feed][:author])
          f.id = sdata_options[:feed][:id]
        end
      end

      def sdata_scope
        options = {}

        if params.key? :predicate
          predicate = SData::Predicate.parse(CGI::unescape(params[:predicate]))
          options[:conditions] = predicate.to_conditions
        end

        sdata_options[:model].all(options)
      end
    end
    
    include AuxilliaryMethods
    include Actions
  end
end

module ActionController
  class Base
    include SData::ControllerMixin
  end
end