require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

include SData

describe ConditionsBuilder do
  describe "#build_conditions" do
    it "should correctly build equality" do
      conditions = ConditionsBuilder.build_conditions 'born_at', :eq, '1900'
      conditions.should == ["#{quoted('born_at')} = ?", '1900']
    end

    it "should correctly build '>'" do
      conditions = ConditionsBuilder.build_conditions 'born_at', :gt, '1900'
      conditions.should == ["#{quoted('born_at')} > ?", '1900']
    end

    it "should correctly build '<'" do
      conditions = ConditionsBuilder.build_conditions 'born_at', :lt, '1900'
      conditions.should == ["#{quoted('born_at')} < ?", '1900']
    end

    it "should currectly build '<=' " do
      conditions = ConditionsBuilder.build_conditions 'born_at', :lteq, '1900'
      conditions.should == ["#{quoted('born_at')} <= ?", '1900']
    end

    it "should currectly build '>='" do
      conditions = ConditionsBuilder.build_conditions 'born_at', :gteq, '1900'
      conditions.should == ["#{quoted('born_at')} >= ?", '1900']
    end

    it "should currectly build '<>'" do
      conditions = ConditionsBuilder.build_conditions 'born_at', :ne, '1900'
      conditions.should == ["#{quoted('born_at')} <> ?", '1900']
    end

    it "should currectly build 'between'" do
      conditions = ConditionsBuilder.build_conditions 'born_at', :between, '1900', '1905'
      conditions.should == ["#{quoted('born_at')} BETWEEN ? AND ?", '1900', '1905']
    end

    it "should return empty hash is arguments are invalid" do
      ConditionsBuilder.build_conditions(nil, :gt, 1).should == {}
      ConditionsBuilder.build_conditions('field', :invalid_relation, 1).should == {}
      ConditionsBuilder.build_conditions('field', :gt).should == {}
      ConditionsBuilder.build_conditions('field', :gt, 'value', 'redundant_value').should == {}
      ConditionsBuilder.build_conditions('field', :between, 'insufficient value').should == {}
    end

    def quoted(column_name)
      ActiveRecord::Base.connection.quote_column_name(column_name)
    end
  end    
end