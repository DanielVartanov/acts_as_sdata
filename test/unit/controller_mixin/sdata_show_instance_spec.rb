require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe ControllerMixin, "#sdata_show_instance" do
  describe "given a controller which acts as sdata" do
    before :all do
      Base = Class.new(ActionController::Base)
      Base.extend ControllerMixin

      Model = Class.new
      Base.acts_as_sdata  :model => Model
    end

    before :each do
      @controller = Base.new
    end

    describe "when params contain :instance_id key" do
      before :each do
        @instance_id = 1
        @controller.stub! :params => { :instance_id => @instance_id }
      end

      describe "when record with such id exists" do
        before :each do
          @record = Model.new
          Model.should_receive(:find_by_sdata_instance_id).with(@instance_id).and_return(@record)
        end

        it "should render atom entry of the record" do
          entry = Atom::Entry.new
          @record.should_receive(:to_atom).and_return(entry)
          @controller.should_receive(:render).with(:xml => entry, :content_type => "application/atom+xml; type=entry")
  
          @controller.sdata_show_instance
        end
      end

      describe "when record with such id does not exist" do
        before :each do
          Model.should_receive(:find_by_sdata_instance_id).with(@instance_id).and_return(nil)
        end

        it "should..." do
          pending "wasn't defined yet"
        end
      end
    end

    describe "whem params does not contain :instance_id key" do
      before :each do
        @controller.stub! :params => Hash.new
      end

      it "should..." do
        pending "wasn't defined yet"
      end
    end
  end
end