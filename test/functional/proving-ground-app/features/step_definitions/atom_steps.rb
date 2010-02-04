def atom_entry
  Atom::Entry.load_entry(response.body)
end

def atom_feed
  Atom::Feed.load_feed(response.body)
end

When /I post the following Atom entry to (.+):$/ do |path, entry|
  header 'Content-Type', Webrat::MIME.mime_type('.atom')
  request_page path, :post, entry
end

When /I PUT the following Atom entry to (.+):$/ do |path, entry|
  header 'Content-Type', Webrat::MIME.mime_type('.atom')
  request_page path, :put, entry
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

Then /response body should contain Atom Feed/ do
  Then %{response content type should be "application/atom+xml; type=feed"}
  lambda { atom_feed }.should_not raise_error
end

Then /feed should contain (\d+) entries/ do |entries_count|
  atom_feed.entries.size.should == entries_count.to_i
end

Then /feed should contain element "(.+)" with value "(.+)"/ do |element_name, value|
  atom_feed.__send__(element_name.to_sym).should == value
end