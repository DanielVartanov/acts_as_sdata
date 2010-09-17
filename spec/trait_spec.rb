require File.join(File.dirname(__FILE__), 'spec_helper')

describe Trait do
  context "when initialized" do
    it "should not raise any errors" do
      Trait.new { blah blah blah }
    end

    it "should not evaluate the code" do
      object = mock()
      Trait.new { object.touch }
      object.should_not_receive(:touch)
    end
  end

  context "given a trait which potentially does a lot" do
    before :all do
      MightyTrait = Trait.new do
        acts_as_sdata :option => :value

        def field; end
        def self.class_field; end
      end
    end

    it "should do his stuff when included" do
      TraitContainer = Class.new
      TraitContainer.should_receive(:acts_as_sdata)

      TraitContainer.send :include, MightyTrait

      TraitContainer.new.should respond_to(:field)
      TraitContainer.should respond_to(:class_field)
    end
  end
end