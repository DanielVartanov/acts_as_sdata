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
        predicate = SData::Predicate.parse(model_class.payload_map.baze_fields, params[:predicate])
        scope = model_class.all(:conditions => predicate.to_conditions)
        if scope.count != 1
          raise Sage::BusinessLogic::Exception::IncompatibleDataException, "Conditions scope must contain exactly one entry"
        end
        scope.first
      end

      def linked_sdata_instance
        SData::SdUuid.find_by_virtual_model_and_uuid(model_class, Predicate.strip_quotes(params[:instance_id]))
      end

      def non_linked_sdata_instance
        model_class.find_by_sdata_instance_id(Predicate.strip_quotes(params[:instance_id]))
      end
    end
  end
end