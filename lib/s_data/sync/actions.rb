module SData
  module Sync
    module Actions
      # TODO: error handling
      def sdata_collection_sync_feed
        # get the target digest
        payload = params[:entry].sdata_payload

        raise "no payload!" if payload.blank?

        sd_sync_run = SData::SdSyncRun.find_by_tracking_id(tracking_id)
        raise Sage::BusinessLogic::Exception::AccessDeniedException, "Access denied" unless sd_sync_run.nil?

        # prepare a sync run to hold our state
        sd_sync_run = SData::SdSyncRun.new(   :tracking_id => tracking_id,
                                              :run_name => params[:runName],
                                              # :created_at => params[:runStamp],
                                              :sd_class => sdata_resource.sdata_name,
                                              :created_by => target_user)
        sd_sync_run.target_digest = payload.sync_digest

        sd_sync_run.start!
        sd_sync_run.process!
        
        headers 'Location' => sync_source_url(sd_sync_run.tracking_id)
        content_type "application/xml"
        status 202
        sd_sync_run.to_xml.to_s
      end

      def sdata_collection_sync_feed_status
        sd_sync_run = SData::SdSyncRun.find_by_tracking_id(tracking_id)
        raise Sage::BusinessLogic::Exception::AccessDeniedException, "Access denied" if sd_sync_run.nil?
        assert_access_to sd_sync_run

        if sd_sync_run.error?
          if sd_sync_run.objects && sd_sync_run.objects.is_a?(Exception)
            raise sd_sync_run.objects
          else
            raise "Unknown Error in Sync"
          end
        end

        if sd_sync_run.finished?
          @total_results = sd_sync_run.total_results
          feed =  build_sdata_feed(:feed => {:title => "#{sdata_resource.sdata_name} synchronization feed #{params[:trackingID]}"})
          feed[SData.config[:schemas]['sync'], 'syncMode'] << "catchUp"

          feed.sync_digest = sd_sync_run.source_digest

          atom_entries = []
          errors = []
          sd_sync_run.objects[zero_based_start_index,records_to_return].each do |obj|
            begin
              # RADAR: this (the (params) part) will allow user to insert a different dataset (and possibly
              # other data) than that which was synchronized during the run. If this is somehow a security
              # problem, need to freeze that data during synctime. an be also solved by freezing username
              # in feed and matching dataset against it at accestime.
              # RADAR: children (e.g. line items) will be embedded in parent (e.g. invoice) during this
              # request, but from live data rather than syncronized one, is this a potential problem?
              feed.entries << obj.to_atom(params.merge(:sync => true)){|entry| entry.sync_syncState = obj.sd_sync_state }
            rescue Exception => e
              errors << ApplicationDiagnosis.new(:exception => e).to_xml(:feed)
            end
          end
          #TODO: syntactic sugar if possible (such as diagnosing_errors(&block) which does the dirty work)
          errors.each do |error|
            feed[SData.config[:schemas]['sdata'], 'diagnosis'] << error
          end
          populate_open_search_for(feed)
          build_feed_links_for(feed)
          content_type "application/atom+xml; type=feed"
          feed.to_xml
        else
          content_type "application/atom+xml; type=feed"
          headers 'Location' => sync_source_url(sd_sync_run.tracking_id)
          status 202
          sd_sync_run.to_xml.to_s
        end
      end

      def sdata_collection_sync_feed_delete
        sd_sync_run = SData::SdSyncRun.find_by_tracking_id(tracking_id)
        sd_sync_run.destroy
        "OK"
      end

      def sdata_collection_sync_results
        "Not implemented!"
      end

    protected
      def syncing?
        params.key? :trackingID
      end

      def resource_url
        syncing? ? super + "/$syncSource('#{tracking_id}')" : super
      end

      def sync_source_url(track)
        endpoint  = target_user.endpoint
        "#{endpoint}/#{SData.sdata_collection_url_component(sdata_resource)}/$syncSource('#{track}')"
      end

      def tracking_id
        CGI::unescape(params[:trackingID]).gsub(/^'/,'').gsub(/'$/,'')
      end
    end
  end
end
