module SData
  module Sync
    module SdataSyncingMixin
      def sd_digest
        SData::SdDigest.find_or_create(self.owner, self.sdata_name)
      end
    
      def sd_sync_state
        @sd_sync_state ||= SdSyncState.find(:first, :conditions => {:sd_uuid_id => self.sd_uuid, :sd_digest_id => self.sd_digest})
      end
    
      def sd_sync_state=(s)
        @sd_sync_state = s
      end
    end
  end
end