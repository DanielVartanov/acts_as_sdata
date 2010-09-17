module SData
  module ControllerMixin
    module SDataInstance

    protected

      def sdata_instance
        if params[:condition] == "$linked"
          linked_sdata_instance
        elsif params.key?(:predicate)
          sdata_instance_by_predicate
        else
          non_linked_sdata_instance
        end
      end

      def sdata_instance_by_predicate
        predicate = SData::Predicate.parse(sdata_resource.payload_map.baze_fields, params[:predicate])
        scope = sdata_resource.all(:conditions => predicate.to_conditions)
        if scope.count != 1
          raise Sage::BusinessLogic::Exception::IncompatibleDataException, "Conditions scope must contain exactly one entry"
        end
        scope.first
      end

      def linked_sdata_instance
        SData::SdUuid.find_by_virtual_model_owner_and_uuid(sdata_resource, target_user, Predicate.strip_quotes(params[:instance_id]))
      end

      def non_linked_sdata_instance
        sdata_resource.find_by_sdata_instance_id(Predicate.strip_quotes(params[:instance_id]))
      end
    end
  end
end
