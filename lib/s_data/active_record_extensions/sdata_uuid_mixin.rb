module SData
  module ActiveRecordExtensions
    module SdataUuidMixin
    
      def acts_as_sdata_uuid
        self.__send__ :extend, UuidClassMethods
      end
    
      module UuidClassMethods

     
        def find_by_virtual_model_owner_and_uuid(virtual_model, owner, uuid)
          sd_uuid = find_uuid_record_for_virtual_model_owner_and_uuid(virtual_model, owner, uuid)
          raise SData::Exceptions::SdUuid::NotFound.new("#{virtual_model.sdata_name} with UUID '#{uuid}' not found") unless sd_uuid
          virtual_model.build_for(sd_uuid.bb_model)    
        end
      
        # Handling multiple uuids: when linking and the resource already had a uuid on both sides, one provider wins and
        # stores it's uuid for the resource on the other provider (http://interop.sage.com/daisy/sdataSync/Link/525-DSY.html)
        # At a later date sdata will provide an algorithm for uuid propagation; for the time being we assume the last stored
        # is the correct one.
        def find_for_virtual_instance(virtual_instance)
          SData::SdUuid.first(:conditions => {:sd_class => virtual_instance.sdata_name, 
                                              :bb_model_type => virtual_instance.baze_class_name, 
                                              :bb_model_id => virtual_instance.baze.id,
                                              :user_id => virtual_instance.owner_id},
                              :order => "updated_at DESC" )
        end
      
        def enforce_uniqueness(sd_uuids, sd_class, baze_class_name)
          return nil if sd_uuids.nil? || sd_uuids.empty?
          if sd_uuids.count > 1
            RAILS_DEFAULT_LOGGER.fatal("SdUuid uniqueness violation for #{sd_class} - #{baze_class_name} - #{uuid}. Using first created")
            sd_uuids.sort_by!{|sid| sid.updated_at}
          end
          sd_uuids.first
        end

        def find_uuid_record_for_virtual_model_owner_and_uuid(virtual_model, owner, uuid)
          sd_uuids = SData::SdUuid.find(:all, :conditions => {:sd_class => virtual_model.sdata_name, 
                                                              :bb_model_type => virtual_model.baze_class_name, 
                                                              :uuid => uuid, 
                                                              :user_id => owner.id})
          sd_uuid = enforce_uniqueness(sd_uuids, virtual_model.sdata_name, virtual_model.baze_class_name)
          sd_uuid
        end
      
        # This method is used to respond to a PUT to $linked('uuid'), to change what bb_model instance a uuid points to
        # TODO this method makes no attempt to handle multiple baze_classes
        # RADAR this method also has a RACE, but which should only happen when the provider/linking engine 
        # is doing something fubarred
        def reassign_uuid!(uuid, virtual_model, owner, new_id)
          raise "Cannot edit uuid for virtual_model (#{virtual_model.name}) with no fixed baze_class." if virtual_model.baze_class.nil?
          sd_uuid = find_uuid_record_for_virtual_model_owner_and_uuid(virtual_model, owner, uuid)
          sd_uuid.update_attributes!({:bb_model_id => new_id})
        end
      
        # TODO: handle case where virtual model depends on multiple models whose updated_at matter. 
        # This method can change the uuid of a given underlying BB model. It CANNOT set a uuid for the tuple [sd_class,
        # bb_model_type] for a given bb_model_id if an instance of the tuple [sd_class, bb_model_type] with a different
        # bb_model_id exists. To swap which bb_model_id of a [sd_class, bb_model_type] a uuid points to, use reassign_uuid!.
        # Move the delete case to a separate method, and the controller should determine whether the request is deleting
        # or not (does spec actually say you can delete a uuid by POST ing empty uuid to it? don't you have to do a DELETE?).
        # Because of unique index on [sd_class, bb_model, uuid] this has a race condition and can theoretically throw, but
        # only if a linking engine is mistakenly sending multiple requests rapidly. The controller can just report a 
        # generic error.
        def create_or_update_uuid_for(virtual_instance, uuid)
          raise "Cannot create_or_update_uuid_for virtual_model (#{virtual_model.name}) with no fixed baze_class." if virtual_instance.class.baze_class.nil?
          raise "virtual_instance #{virtual_instance.inspect} has no baze" unless virtual_instance.baze
          return if uuid.blank?

          sd_uuid = SData::SdUuid.find_for_virtual_instance(virtual_instance)
          params = {:sd_class => virtual_instance.sdata_name,
                    :bb_model_type => virtual_instance.baze_class_name,
                    :bb_model_id => virtual_instance.baze.id,
                    :user_id => virtual_instance.owner_id,
                    :uuid => uuid}
          if sd_uuid
            sd_uuid.update_attributes!(params)
          else
            begin
              SData::SdUuid.create(params)
            rescue ::ActiveRecord::StatementInvalid
              raise Sage::BusinessLogic::Exception::IncompatibleDataException, "UUID already exists for another resource"
            end
          end
        end
      end
    end
  
    module SdataUuidableMixin
      def has_sdata_uuid
        self.__send__ :include, UuidableInstanceMethods
      end
    
      module UuidableInstanceMethods
            
        def uuid
          record = sd_uuid
          record ? record.uuid : nil
        end
      
        # WARN: don't cache this, it will potentially break things
        # RADAR: This finds the most recently updated of potentially many sd_uuids -- see
        # http://interop.sage.com/daisy/sdataSync/Link/525-DSY.html, linking scenario 3
        def sd_uuid
          result = SData::SdUuid.find_for_virtual_instance(self)
          if result.nil? && (uuid = self.sdata_uuid_for_record)
            if !SData::SdUuid.find_uuid_record_for_virtual_model_owner_and_uuid(self.class, self.owner, uuid)
              result = create_or_update_uuid!(uuid)
            else
              SData::SdUuid.reassign_uuid!(uuid, self.class, self.owner, self.baze.id)
              result = self
            end
          end
          result
        end

        def create_or_update_uuid!(value)
          SData::SdUuid.create_or_update_uuid_for(self, value)
        end
      
        def linked?
          !sd_uuid.nil?
        end
      
      end
    end
  
    ::ActiveRecord::Base.extend SdataUuidMixin
  end
end