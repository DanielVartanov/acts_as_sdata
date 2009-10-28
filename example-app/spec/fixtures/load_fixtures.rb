def attributes_from_match_data(attributes_names, match_data)
  attributes = {}
  attributes_names.each_with_index do |attribute_name, index|
    attrubute_value = match_data[index + 1]
    attributes[attribute_name.to_sym] = attrubute_value
  end
  attributes
end

President.delete_all

File.open(File.join(File.dirname(__FILE__), 'presidents.txt')) do |file|
  while (line = file.gets)    
    match_data = line.match /(\d{1,2}). (\w*).*\s(\w*) \((\d{4})-(\d{4}|\s)\)\s*(.*)\s*(\d{4})-(\d{4}|\s)/

    attributes_names = %w(order first_name last_name born_at died_at party term_started_at term_ended_at)
    president_attributes = attributes_from_match_data(attributes_names, match_data)

    President.create!(president_attributes)
  end
end