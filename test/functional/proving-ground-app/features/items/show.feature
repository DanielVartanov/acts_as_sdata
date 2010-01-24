Feature: Show item

Background:
  Given there are "First" item

Scenario: Agent gets an item
  When I get /items/1.xml  