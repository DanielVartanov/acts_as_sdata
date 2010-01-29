Feature: Get SData instance

  Scenario: Agent gets SData instance by id
    Given there is "First" item
    When I get /items/!1    
    Then response should contain Atom entry
    And entry should have element "title" with value "Item 'First' (id #1)"
    And entry should have SData extension element "id" with value "1"
    And entry should have SData extension element "name" with value "First"