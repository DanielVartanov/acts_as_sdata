When /^I get (.+)$/ do |page_address|
  get page_address, nil
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

Then /^show me response body$/ do
  puts response_body
end

Then /^show me response$/ do
  require 'pp'
  pp response
end