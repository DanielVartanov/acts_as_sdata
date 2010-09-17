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
          content_type 'application/atom+xml; type=feed'
          collection.to_xml
        end
      end

      def sdata_show_instance
        instance = sdata_instance
        assert_access_to instance
        content_type "application/atom+xml; type=entry"
        instance.to_atom(params).to_xml
      end

      def sdata_create_instance
        raise "not currently supported"
      end

      def sdata_update_instance
        raise "not currently supported"
      end

      def sdata_create_link
          payload_xml = params[:entry].sdata_payload.raw_xml
          payload = Nokogiri::XML(payload_xml).root
          id = payload.attributes['key'].value.to_i
          uuid = payload.attributes['uuid'].value
          instance = sdata_resource.find(id)
          assert_access_to instance
          instance.create_or_update_uuid! uuid
          content_type "application/atom+xml; type=entry"
          status 201
          instance.to_atom(params).to_xml
      end

    protected      

      def assert_access_to(instance)
        raise "Unauthenticated" unless logged_in?
        # Not returning Access Denied on purpose so that users cannot fish for existence of emails or other data.
        # As far as user should be concerned, all requests are scoped to his/her own data.
        # Data which is found but which belongs to someone else should
        # be as good as data that doesn't exist.
        raise Sage::BusinessLogic::Exception::IncompatibleDataException, "Conditions scope must contain exactly one entry" unless accessible?(instance)
      end

      def accessible?(instance)
        instance.owner == current_user or instance.owner.biller.bookkeepers.include?(current_user.bookkeeper)
      end

      def handle_exception(exception)
        diagnosis = SData::Diagnosis::DiagnosisMapper.map(exception)

        status diagnosis.http_status_code || 500
        content_type 'application/xml'

        diagnosis.to_xml(:root)
        exception.to_s
      end

      include SDataInstance
      include SDataFeed
      include CollectionScope
    end
  end
end
