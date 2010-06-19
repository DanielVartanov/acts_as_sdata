module SData
  module ControllerMixin
    module CollectionScope

    protected

      def where_clause?
        !! where_clause
      end

      def where_clause
        expression = params.to_a.select{ |pair| pair[1].nil? }.flatten.compact.first
        expression.nil? ? nil : expression.match(/where\s(.*)/)[0]
      end

      #(name eq 'asdf') -> options[:conditions] = ['"name" eq ?', 'asdf']
      def sdata_scope
        options = {}

        if where_clause?
          predicate = SData::Predicate.parse(model_class.payload_map.baze_fields, where_clause)
          options[:conditions] = predicate.to_conditions
        end

        if sdata_options[:scoping]
          options[:conditions] ||= []
          sdata_options[:scoping].each do |scope|
            options[:conditions][0] = [options[:conditions].to_a[0], scope].compact.join(' and ')
            1.upto(sdata_options[:scope_param_size] || 1) do
              options[:conditions] << target_user.id.to_s
            end
          end
        end

        if params.key? :condition
          options[:conditions] ||= []
          if params[:condition] == "$linked"
            virtual_class = sdata_options[:model].to_s.demodulize
            baze_class = sdata_options[:model].baze_class.name.demodulize
            condition = "id IN (SELECT bb_model_id FROM sd_uuids WHERE bb_model_type = '#{baze_class}' and sd_class = '#{virtual_class}')"
            options[:conditions][0] = [options[:conditions].to_a[0], condition].compact.join(' and ')
          end
        end

        #FIXME: this is an unoptimized solution that may be a bottleneck for large number of matches
        #if user has hundreds of records but requests first 10, we shouldnt load them all into memory
        #but use sql query to count how many exist in total, and then load the first 10 only

        #FIXME: do not return records deleted through acts_as_paranoid!
        results = sdata_options[:model].all(options)
        @total_results = results.count
        paginated_results = results[zero_based_start_index, records_to_return]
        paginated_results.to_a
      end
    end
  end
end