require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

include SData

describe ActiveRecordMixin, "#find_by_sdata_instance_id" do
  describe "given a class extended by ActiveRecordExtentions" do
    before :all do
      Model = Class.new(ActiveRecord::Base)
      Model.__send__ :include, ActiveRecordMixin
    end

    describe "when @@sdata_options contain :instance_id" do
      before :each do
        Model.class_eval { acts_as_sdata :instance_id => :email }
      end

      it "should find by a field assigned to :instance_id option value" do
        email = "e@ma.il"
        Model.should_receive(:find).with(:first, :conditions => { :email => email }).once
        Model.find_by_sdata_instance_id(email)
      end
    end

    describe "when @@sdata_options does not contain :instance_id" do
      before :each do
        Model.class_eval { acts_as_sdata }
      end

      it "should consider :id as SData instance ID" do
        id = 1
        Model.should_receive(:find).with(id).once
        Model.find_by_sdata_instance_id(id)
      end
    end
  end
end