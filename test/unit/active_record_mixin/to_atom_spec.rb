require File.join(File.dirname(__FILE__), '..', 'spec_helper')
                                                          

describe SData::ActiveRecordExtensions::Mixin, "#to_atom" do
  describe "given a class extended by ActiveRecordExtensions" do
    before :all do
      Base = Class.new
      class Base
        def self.name
          super_name = super
          "SData::Contracts::CrmErp::#{super_name}"
        end
      end
      Base.extend SData::ActiveRecordExtensions::Mixin
    end

    describe "when .acts_as_sdata is called without arguments" do
      before :each do
        Base.class_eval { acts_as_sdata }
        @model = Base.new
        @model.stub! :id => 1, :name => 'John Smith', :updated_at => Time.now - 1.day, :created_by => @model, :sage_username => 'basic_user' 
        @model.stub! :sdata_content => "Base ##{@model.id}: #{@model.name}", :attributes => {}
      end

      it "should return an Atom::Entry instance" do
        # begin
        @model.to_atom(:dataset => '-').should be_kind_of(Atom::Entry)
        # rescue Exception => e
        #   puts "e: #{e.inspect}"
        # puts(e.backtrace.join("\n"))
        # end
      
      end

      it "should assign model name to Atom::Entry#content" do
        @model.to_atom(:dataset => '-').content.should == 'Base #1: John Smith'
      end

      it "should assign model name and id to Atom::Entry#title" do
        @model.to_atom(:dataset => '-').title.should == 'Base 1'
      end

      it "should assign Atom::Entry#updated" do
        Time.parse(@model.to_atom(:dataset => '-').updated).should < Time.now-1.day
        Time.parse(@model.to_atom(:dataset => '-').updated).should > Time.now-1.day-1.minute        
      end

      it "should assign Atom::Entry#links" do
        @model.to_atom(:dataset => '-').links.size.should == 1
        @model.to_atom(:dataset => '-').links[0].rel.should == 'self'
        @model.to_atom(:dataset => '-').links[0].href.should == "http://www.example.com/sdata/example/myContract/-/bases('1')"
      end

      it "should assign Atom::Entry#links when param query is present" do
        @model.to_atom(:dataset => '-', :select => 'attribute').links.size.should == 1
        @model.to_atom(:dataset => '-', :select => 'attribute').links[0].rel.should == 'self'
        @model.to_atom(:dataset => '-', :select => 'attribute').links[0].href.should == "http://www.example.com/sdata/example/myContract/-/bases('1')?select=attribute"
      end

      it "should assign Atom::Entry::id" do
        @model.to_atom(:dataset => '-').id.should == "http://www.example.com/sdata/example/myContract/-/bases('1')"
      end

      it "should assign Atom::Entry::categories" do
        @model.to_atom.categories.size.should == 1
        @model.to_atom.categories[0].term.should == "base"
        @model.to_atom.categories[0].label.should == "Base"
        @model.to_atom.categories[0].scheme.should == "http://schemas.sage.com/sdata/categories"
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
        @model.to_atom.content.should == 'Base #1: Test'
      end
    end
  end
end