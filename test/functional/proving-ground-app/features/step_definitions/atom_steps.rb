def atom_entry
  Atom::Entry.load_entry(response.body)
end

Then /response should contain Atom entry/ do
  Then %{response content type should be "application/atom+xml; type=entry"}
  lambda { atom_entry }.should_not raise_error
end

Then /entry should have element "(.+)" with value "(.+)"/ do |element_name, value|
  atom_entry.__send__(element_name.to_sym).should == value
end

Then /entry should have SData extension element "(.+)" with value "(.+)"/ do |element_name, value|
  atom_entry['http://sdata.sage.com/schemes/attributes', element_name].first.should == value
end