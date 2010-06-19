module SData
  class Predicate < Struct.new(:field, :relation, :value)
    def self.parse(fields_map, predicate_string)
      # Gotcha on Rightscale that escaped + before it hits controller, but doesn't escape other special chars!
      escaped_predicate_string = CGI::unescape(predicate_string.gsub('+', '%2B')) 
      match_data = escaped_predicate_string.match(/(\w+)\s(gt|lt|eq|ne|lteq|gteq)\s('?.+'?|'')/) || []

      canonical_field_name = match_data[1].underscore.to_sym unless match_data[1].nil?
      self.new fields_map[canonical_field_name], match_data[2], strip_quotes(match_data[3])
    end

    def self.strip_quotes(value)
      return value unless value.is_a?(String)
      value = value.gsub("%27", "'")
      return value unless value =~ /'.*?'/
      return value[1,value.length-2]
    end

    def to_conditions      
      if valid?
        ConditionsBuilder.build_conditions field, relation.to_sym, value
      else
        raise Sage::BusinessLogic::Exception::IncompatibleDataException, "Invalid predicate string"
      end
    end

    def valid?
      field && relation && value
    end
  end
end