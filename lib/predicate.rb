module SData
  class Predicate < Struct.new(:field, :relation, :value)
    def self.parse(predicate_string)

      match_data = predicate_string.match(/(\w+)\s(gt|lt|eq)\s('?.+'?|'')/) || []
      self.new match_data[1], match_data[2], strip_quotes(match_data[3])
    end

    def self.strip_quotes(value)
     return value unless value =~ /'.*?'/
     return value[1,value.length-2]
    end

    def to_conditions      
      if field && relation && value
        ConditionsBuilder.build_conditions field, relation.to_sym, value
      else
        {}
      end
    end
  end
end