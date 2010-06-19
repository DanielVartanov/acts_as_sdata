require 'nokogiri'

module SData
  module ControllerMixin
    module Actions
      def sdata_collection
        begin
          errors = []
          collection = build_sdata_feed
          sdata_scope.each do |entry|
            begin
              collection.entries << entry.to_atom(params)
            rescue Exception => e
              errors << ApplicationDiagnosis.new(:exception => e).to_xml(:feed)
            end
          end
          #TODO: syntactic sugar if possible (such as diagnosing_errors(&block) which does the dirty work)
          errors.each do |error|
            collection[SData.config[:schemas]['sdata'], 'diagnosis'] << error
          end
          populate_open_search_for(collection)
          build_feed_links_for(collection)
          render :xml => collection, :content_type => "application/atom+xml; type=feed"
        rescue Exception => e
          handle_exception(e)
        end
      end

      def sdata_show_instance
        begin
          instance = sdata_instance
          assert_access_to instance
          render :xml => instance.to_atom(params), :content_type => "application/atom+xml; type=entry"
        rescue Exception => e
          handle_exception(e)
        end
      end

      def sdata_create_instance
        raise "not currently supported"
      end

      def sdata_update_instance
        raise "not currently supported"
      end

      def sdata_create_link
        begin
          payload_xml = params['entry'].sdata_payload.raw_xml
          payload = Nokogiri::XML(payload_xml).root
          id = payload.attributes['key'].value.to_i
          uuid = payload.attributes['uuid'].value
          instance = model_class.find(id)
          assert_access_to instance
          instance.create_or_update_uuid! uuid
          render :xml => instance.to_atom(params), :content_type => "application/atom+xml; type=entry", :status => "201"
        rescue Exception => e
          handle_exception(e)
        end
      end

    protected

      def model_class
        self.class.sdata_options[:model]
      end

      def assert_access_to(instance)
        raise "Unauthenticated" unless logged_in?
        # Not returning Access Denied on purpose so that users cannot fish for existence of emails or other data.
        # As far as user should be concerned, all requests are scoped to his/her own data.
        # Data which is found but which belongs to someone else should be as good as data that doesn't exist.
        raise Sage::BusinessLogic::Exception::IncompatibleDataException, "Conditions scope must contain exactly one entry" if (instance.owner != target_user)
      end

      
      def handle_exception(exception)
        diagnosis = SData::Diagnosis::DiagnosisMapper.map(exception)
        render :xml => diagnosis.to_xml(:root), :status => diagnosis.http_status_code || 500
      end

      include SDataInstance
      include SDataFeed
      include CollectionScope
    end
  end
end