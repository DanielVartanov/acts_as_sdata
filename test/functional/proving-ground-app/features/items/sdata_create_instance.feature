Feature: Create SData instance

  Scenario: Agent creates a new instance successfully
    When I post the following Atom entry to /items:
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:attributes="http://sdata.sage.com/schemes/attributes">
          <attributes:name>First</attributes:name>
        </entry>
        """
    Then response should contain Atom entry
    And response status should be 201 (Created)
    And entry should have SData extension element "id" with value "1"

  Scenario: Agent fails to create a new instance
    When I post the following Atom entry to /items:
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <entry xmlns="http://www.w3.org/2005/Atom">
        </entry>
        """
    Then response status should be 400 (Bad Request)
    And response should contain XML document
    And XML document should contain the following at XPath /errors:
        """
        <errors><error>Name can't be blank</error></errors>

        """