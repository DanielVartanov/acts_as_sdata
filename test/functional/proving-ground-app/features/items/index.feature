Feature: Items index

Background:
  Given there is "First" item
  And there is "Second" item

Scenario: Agent gets index of items
  When I get /items