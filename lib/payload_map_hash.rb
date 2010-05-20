module SData
  module PayloadMap
    class PayloadMapHash < Hash
      def initialize(hash)
        merge!(hash)
      end

      def static_values
        subset :static_value
      end

      def baze_fields
        subset :baze_field
      end

    protected

      def subset(mapping_type)
        raw_subset = select { |key, value| value.has_key?(mapping_type) }
        hash = Hash[raw_subset]
        hash.merge(hash) { |key, value| value[mapping_type] }
      end
    end
  end
end