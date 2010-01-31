Given /global ETag stub value is "(.+)"/ do |etag|
  ActionController::Response.any_instance.stubs(:etag).returns(etag)
end

When /I get ([\w\/!\(\)]+) with the following headers:$/ do |path, headers|
  headers.hashes.each do |header_hash|
    header header_hash[:name], header_hash[:value]
  end
  request_page path, :get, {}
end

When /^I get ([\w\/!\(\)]+)$/ do |path|
  get path, nil
end

When /^I post to (.+) with:$/ do |page_address, data|
  header 'Content-Type', Webrat::MIME.mime_type('.xml')
  request_page page_address, :post, data
end

Then /response status should be (\d+)/ do |code|
  response.code.to_i.should == code.to_i
end

Then /response content type should be "(.+)"/ do |content_type|
  response.headers["Content-Type"].should == content_type
end

Then /response body should be empty/ do
  response_body.should be_empty
end

Then /^show me response body$/ do
  puts response_body
end

Then /^show me response$/ do
  require 'pp'
  pp response
end

Then /^show me request$/ do
  require 'pp'
  pp response.request
end