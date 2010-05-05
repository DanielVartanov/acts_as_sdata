Feature: Update SData instance

  Scenario: Agent updates SData instance successfully
    Given there is "First" item with ETag "686897696a7c876b7e"
    When I set the following headers:
        | name          | value              |
        | If-None-Match | 686897696a7c876b7e |
    And I PUT the following Atom entry to /items('1'):
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:attributes="http://sdata.sage.com/schemes/attributes">
          <attributes:name>First-Updated</attributes:name>
        </entry>
        """
    Then response status should be 200 (OK)
    When I get /items('1')
    #Then entry should have SData extension element "name" with value "First-Updated"

  Scenario: Agent appemts to update SData with wrong ETag
    Given there is "First" item with ETag "557698a76b76ab4434"
    When I set the following headers:
        | name          | value              |
        | If-None-Match | 686897696a7c876b7e |
    And I PUT the following Atom entry to /items('1'):
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:attributes="http://sdata.sage.com/schemes/attributes">
          <attributes:name>First-Updated</attributes:name>
        </entry>
        """
    Then response status should be 412 (Precondition Failed)

  Scenario: Agent attempts to update SData instance without providing a ETag
    Given there is "First" item with ETag "686897696a7c876b7e"
    When I PUT the following Atom entry to /items('1'):
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:attributes="http://sdata.sage.com/schemes/attributes">
          <attributes:name>First-Updated</attributes:name>
        </entry>
        """
    Then response status should be 412 (Precondition Failed)

  Scenario: Agents attempts to set invalid values
    Given there is "First" item with ETag "686897696a7c876b7e"
    When I set the following headers:
        | name          | value              |
        | If-None-Match | 686897696a7c876b7e |
    When I PUT the following Atom entry to /items('1'):
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:attributes="http://sdata.sage.com/schemes/attributes">
          <attributes:name></attributes:name>
        </entry>
        """
    Then response status should be 400 (Bad Request)
    And response should contain XML document
    And XML document should contain the following at XPath /errors:
        """
        <errors>
            <error>Name can't be blank</error>
        </errors>

        """

  Scenario: Agents doesn't change any field
    Given there is "First" item with ETag "686897696a7c876b7e"
    When I set the following headers:
        | name          | value              |
        | If-None-Match | 686897696a7c876b7e |
    When I PUT the following Atom entry to /items('1'):
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <entry xmlns="http://www.w3.org/2005/Atom">
        </entry>
        """
    Then response status should be 200 (OK)