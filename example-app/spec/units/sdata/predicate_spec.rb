require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

include SData

describe Predicate do
  describe "when predicate string is valid" do
    before :each do
      @predicate = Predicate.parse('born_at gt 1900')
    end

    it "should parse predicate string correctly" do
      ConditionsBuilder.should_receive(:build_conditions).with('born_at', :gt, '1900')
      @predicate.to_conditions
    end
  end

  describe "predicate string is invalid" do
    before :each do
      @predicate = Predicate.parse('blah-blah-blah')
    end

    it "should return empty hash" do
      ConditionsBuilder.should_not_receive :build_conditions
      @predicate.to_conditions.should == {}
    end
  end
end