require File.join(File.dirname(__FILE__), '..', 'spec_helper')
                                                          
include SData

describe ActiveRecordMixin, "#to_atom" do
  describe "given a class extended by ActiveRecordExtentions" do
    before :all do
      Base = Class.new
      Base.extend ActiveRecordMixin
    end

    describe "when .acts_as_sdata is called without arguments" do
      before :each do
        Base.class_eval { acts_as_sdata }
        @model = Base.new
        @model.stub! :id => 1, :name => 'John Smith', :updated_at => Time.now - 1.day, :created_by => @model, :sage_username => 'basic_user' 
        @model.stub! :sdata_content => "Base ##{@model.id}: #{@model.name}", :attributes => {}
      end

      it "should return an Atom::Entry instance" do
        @model.to_atom.should be_kind_of(Atom::Entry)
      end

      it "should assign model name to Atom::Entry#content" do
        @model.to_atom.content.should == 'Base #1: John Smith'
      end

      it "should assign model name and id to Atom::Entry#title" do
        @model.to_atom.title.should == 'Base 1'
      end

      it "should assign Atom::Entry#updated" do
        pending
      end

      it "should assign Atom::Entry#links" do
        pending
      end

      it "should assign Atom::Entry::id" do
        pending
      end
      #FIXME: use xml parser instead of hash so we get proper namespace support
      it "should populate payload from payload map" do
        @model.stub! :payload_map => { :last_name => {:value => 'Washington'}, :first_name => {:value => "George"} }
        atom_entry = @model.to_atom
        hash = Hash.from_xml(atom_entry.to_xml)
        hash['entry']['payload'].should == {"base"=>{"sdata:key"=>"1", "last_name"=>"Washington", "first_name"=>"George"}}
      end

#      it "should expose activerecord attributes in a simple XML extension" do
#        @model.stub! :attributes => { :last_name => "Washington", :first_name => "George" }
#        atom_entry = @model.to_atom
#        atom_entry['http://sdata.sage.com/schemes/attributes'].should == { 'last_name' => ["Washington"], 'first_name' => ["George"] }
#      end
    end

    describe "when .acts_as_sdata is called with arguments" do
      before :each do
        Base.class_eval do
          acts_as_sdata :title => lambda { "#{id}: #{name}" },
                        :content => lambda { "#{name}" }

          def attributes; {} end
        end

        @model = Base.new
        @model.stub! :id => 1, :name => 'Test', :updated_at => Time.now - 1.day, :created_by => @model, :sage_username => 'basic_user' 
        @model.stub! :sdata_content => "Base ##{@model.id}: #{@model.name}",  :to_xml => ''

      end

      it "should evaulate given lambda's in the correct context" do
        @model.to_atom.title.should == '1: Test'
        @model.to_atom.content.should == 'Test'
      end
    end
  end
end