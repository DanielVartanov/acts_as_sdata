Given /there is "(.*)" item$/ do |item_name|
  Item.create! :name => item_name
end

Given /there are following items:$/ do |items|
  items.raw.each do |item_fields|
    Given %{there is "#{item_fields.first}" item}
  end
end

Given /there is "(.*)" item with ETag "(.*)"$/ do |item_name, etag|
  Given %{there is "#{item_name}" item}
  And %{global ETag stub value is "#{etag}"}
end