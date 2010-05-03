Feature: Get SData instance

  Scenario: Agent gets SData instance by id
    Given there is "First" item
    When I get /items/!1
    Then response should contain Atom entry
    And entry should have element "title" with value "Item 'First' (id #1)"
    And entry should have element "id" with value "http://www.example.com/sdata/example/crmErp/-/items('1')"

    #FIXME: Daniel -- not sure what this test does, but it breaks. Not sure how to fix it.
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

  Scenario: SData entry contains a payload info
    Given there is an item with the following properties:
        | Name | First                                |
        | UUID | 88815929-A503-4fcb-B5CC-F1BB8ECFC874 |
    When I get /items/!1
    Then XML document should contain the following at XPath /content/payload:
        """
        <payload xmlns="http://schemas.sage.com/sdata/2008/1">
            <tradingAccount
              sdata:uuid="88815929-A503-4fcb-B5CC-F1BB8ECFC874"
              sdata:url="http://www.billingboss.com/myApp/myContract/-/tradingAccounts/!First"
              xmlns="xmlns="http://schemas.sage.com/crmErp"
            />
        </payload>
        """