Feature: Get SData instance

  Scenario: Agent gets SData instance by id
    Given there is "First" item
    When I get /items/!1
    Then response should contain Atom entry
    And entry should have element "title" with value "Item 'First' (id #1)"
    And entry should have SData extension element "id" with value "1"
    And entry should have SData extension element "name" with value "First"

  Scenario: Agents requests conditional GET (resource is unmodified)
    Given there is "First" item with ETag "686897696a7c876b7e"
    When I get /items/!1 with the following headers:
        | name          | value              |
        | If-None-Match | 686897696a7c876b7e |    
    Then response status should be 304 (Not Modified)
    And response body should be empty

  Scenario: Agents requests conditional GET (resource is modified)
    Given there is "First" item with ETag "557698a76b76ab4434b"
    When I get /items/!1 with the following headers:
        | name          | value              |
        | If-None-Match | 686897696a7c876b7e |
    Then response status should be 200 (OK)
    And response should contain Atom entry