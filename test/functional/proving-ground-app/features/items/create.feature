Feature: create item

Scenario: Agent creates an item
  When I post to /items.xml with:
    """
<?xml version="1.0" encoding="UTF-8"?>
<item>
  <name>first</name>
</item>
    """
  Then response status should be 201  
  And response body should have XPath /item/id
  