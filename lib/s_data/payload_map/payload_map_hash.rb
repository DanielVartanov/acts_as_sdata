module SData
  module PayloadMap
    class PayloadMapHash < Hash
      def initialize(hash)
        merge!(hash)
      end

      def attrs
        reject{|k,v| ! [:static_value, :baze_field].any?{|type| v.has_key?(type)} }
      end
      
      def static_values
        subset :static_value
      end

      def baze_fields
        subset :baze_field
      end

      def procs
        subset :proc
      end

      def procs_with_deleted
        subset :proc_with_deleted, :proc
      end

    protected

      def subset(*mapping_type)
        mapping_type = [mapping_type].flatten
        raw_subset = select { |key, value| mapping_type.any?{|type| value.has_key?(type) }}
        hash = Hash[raw_subset]
        hash.merge(hash){ |key, value| value[mapping_type.detect{|type| value.include?(type)}] }
      end
      
    end
  end
end