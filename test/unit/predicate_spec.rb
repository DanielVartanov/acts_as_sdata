require File.join(File.dirname(__FILE__), 'spec_helper')

include SData

describe Predicate do
  describe "when predicate string is valid" do
    it "should parse predicate string correctly" do
      @predicate = Predicate.parse("born_at gt 1900")
      ConditionsBuilder.should_receive(:build_conditions).with('born_at', :gt, '1900')
      @predicate.to_conditions
    end

    it "should strip wrapper quote marks" do
      @predicate = Predicate.parse("born_at gt '1900'")
      ConditionsBuilder.should_receive(:build_conditions).with('born_at', :gt, '1900')
      @predicate.to_conditions
    end
    
    it "should accept non-alphanumeric characters as part of the value" do
      @predicate = Predicate.parse("born_at gt '1`~!@\#$%^&*()_-+={[}]\|'\";:900'")
      ConditionsBuilder.should_receive(:build_conditions).with('born_at', :gt, "1`~!@\#$%^&*()_-+={[}]\|'\";:900")
      @predicate.to_conditions
    end

    it "should accept quote-marked empty string" do
      @predicate = Predicate.parse("born_at gt ''")
      ConditionsBuilder.should_receive(:build_conditions).with('born_at', :gt, "")
      @predicate.to_conditions
    end
  end

  describe "predicate string is invalid" do

    it "should not accept unrecognized format" do
      @predicate = Predicate.parse('blah-blah-blah')
      ConditionsBuilder.should_not_receive :build_conditions
      @predicate.to_conditions.should == []
    end

    it "should not accept non-quote-marked empty string" do
      @predicate = Predicate.parse('born_at gt ')
      ConditionsBuilder.should_not_receive :build_conditions
      @predicate.to_conditions.should == []
    end
  end
end