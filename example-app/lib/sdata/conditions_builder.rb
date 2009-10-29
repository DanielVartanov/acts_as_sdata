module SData
  class ConditionsBuilder
    SQL_RELATIONS_MAP = {
        :binary => {                              
            :eq => '%s = ?',
            :ne => '%s <> ?',
            :lt => '%s < ?',
            :lteq => '%s <= ?',
            :gt => '%s > ?',
            :gteq => '%s >= ?'
        },
        
        :ternary => {
            :between => '%s BETWEEN ? AND ?'
        }
    }

    attr_accessor :field, :relation, :values
    
    def self.build_conditions(field, relation, *values)
      self.new(field, relation, *values).conditions
    end
    
    def initialize(field, relation, *values)
      @field = field
      @relation = relation
      @values = values
    end

    def conditions
      arguments_invalid? ?
        {} :
        [template_with_field_name] + values
    end

  protected    

    def arguments_invalid?
      field.nil? or relation.nil? or values.nil? or template.nil?
    end

    def template_with_field_name
      template % quoted_field_name
    end
    
    def quoted_field_name
      ActiveRecord::Base.connection.quote_column_name(@field)
    end

    def template
      case values.size
        when 1:
          SQL_RELATIONS_MAP[:binary][relation]
        when 2:
          SQL_RELATIONS_MAP[:ternary][relation]
      end
    end
  end
end