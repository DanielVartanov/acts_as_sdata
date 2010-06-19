require File.join(File.dirname(__FILE__), 'spec_helper')

include SData

describe Predicate do
  context "when predicate string is valid" do
    it "should convert given field name from hungarian notation to underscore notation" do
      @predicate = Predicate.parse({ :born_at => :born_at }, "bornAt gt 1900")
      ConditionsBuilder.should_receive(:build_conditions).with(:born_at, :gt, '1900')
      @predicate.to_conditions
    end

    it "should change field name according to a given map" do
      @predicate = Predicate.parse({ :born_at => :crafted_at }, "bornAt gt 1900")
      ConditionsBuilder.should_receive(:build_conditions).with(:crafted_at, :gt, '1900')
      @predicate.to_conditions
    end

    it "should parse predicate string correctly" do
      @predicate = Predicate.parse({ :born_at => :born_at }, "bornAt gt 1900")
      ConditionsBuilder.should_receive(:build_conditions).with(:born_at, :gt, '1900')
      @predicate.to_conditions
    end

    it "should strip wrapper quote marks" do
      @predicate = Predicate.parse({ :born_at => :born_at }, "bornAt gt '1900'")
      ConditionsBuilder.should_receive(:build_conditions).with(:born_at, :gt, '1900')
      @predicate.to_conditions
    end
    
    it "should accept non-alphanumeric characters as part of the value" do
      @predicate = Predicate.parse({ :born_at => :born_at }, "bornAt gt '1`~!@\#$%^&*()_-+={[}]\|'\";:900'")
      ConditionsBuilder.should_receive(:build_conditions).with(:born_at, :gt, "1`~!@\#$%^&*()_-+={[}]\|'\";:900")
      @predicate.to_conditions
    end

    it "should accept quote-marked empty string" do
      @predicate = Predicate.parse({ :born_at => :born_at }, "bornAt gt ''")
      ConditionsBuilder.should_receive(:build_conditions).with(:born_at, :gt, "")
      @predicate.to_conditions
    end

    context "when condition contains 'ne' relation" do
      it "should parse it correctly" do
        @predicate = Predicate.parse({ :born_at => :born_at }, "bornAt ne 1900")
        ConditionsBuilder.should_receive(:build_conditions).with(:born_at, :ne, "1900")
        @predicate.to_conditions
      end
    end
  end

  context "when predicate string is somehow invalid" do
    it "should raise exception" do
      lambda { Predicate.parse({}, 'bornAt eq 1900').to_conditions }.should raise_error
      lambda { Predicate.parse({}, 'alea jacta est').to_conditions }.should raise_error
      lambda { Predicate.parse({}, 'blahBlahBlah').to_conditions }.should raise_error
    end
  end
end