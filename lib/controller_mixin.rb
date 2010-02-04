module SData
  module ControllerMixin
    def acts_as_sdata(options)
      cattr_accessor :sdata_options
      self.sdata_options = options

      self.__send__ :include, InstanceMethods
    end

    module InstanceMethods
      module Actions
        def sdata_collection
          collection = build_sdata_feed
          collection.entries += sdata_scope.map(&:to_atom)

          render :xml => collection, :content_type => "application/atom+xml; type=feed"
        end

        def sdata_show_instance
          instance = model_class.find_by_sdata_instance_id(params[:instance_id])
          render :xml => instance.to_atom, :content_type => "application/atom+xml; type=entry"
        end

        def sdata_create_instance
          new_instance = model_class.new(params[:entry].to_attributes)
          if new_instance.save
            render :xml => new_instance.to_atom.to_xml, :status => :created, :content_type => "application/atom+xml; type=entry"
          else
            render :xml => new_instance.errors.to_xml, :status => :bad_request
          end
        end

        def sdata_update_instance
          instance = model_class.find_by_sdata_instance_id(params[:instance_id])
          response.etag = [instance]
          if request.fresh?(response)
            if instance.update_attributes(params[:entry].to_attributes)
              response.etag = [instance]
              render :xml => instance.to_atom.to_xml, :content_type => "application/atom+xml; type=entry"
            else
              render :xml => instance.errors.to_xml, :status => :bad_request
            end
          else
            render :text => nil, :status => :precondition_failed
          end
        end
      end

      module AuxilliaryMethods
        protected

        def model_class
          self.class.sdata_options[:model]
        end

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
      
      include Actions
      include AuxilliaryMethods
    end
  end
end

ActionController::Base.extend SData::ControllerMixin