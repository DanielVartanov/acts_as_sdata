Feature: Items index

Background:
  Given there are "First" item
  And there are "Second" item

Scenario: Agent gets index of items
  When I get /items.xml  