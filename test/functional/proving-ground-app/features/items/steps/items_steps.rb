Given /there are "(.*)" item/ do |item_name|
  Item.create! :name => item_name
end