Feature: Get SData collection

  Background:
    Given there are following items:
      | First     |
      | Second    |
      | Third     |

  Scenario: Agent gets SData collection
    When I get /items
    Then response body should contain Atom Feed
    And feed should contain element "title" with value "Items"
    And feed should contain 3 entries

  Scenario: Agent gets SData collection with predicate
    When I get /items(id gt 1)
    Then response body should contain Atom Feed
    And feed should contain 2 entries

  Scenario: Agent gets SData collection with too exacting predicate
    When I get /items(name eq Fifth)
    Then response body should contain Atom Feed
    And feed should contain 0 entries
    
  Scenario: Agent gets SData collection with exact predicate
    When I get /items(name eq Second)
    Then response body should contain Atom Feed
    And feed should contain 1 entries
    
  Scenario: Agent gets SData collection with predicate in quotes
    When I get /items(name eq 'Second')
    Then response body should contain Atom Feed
    And feed should contain 1 entries

  Scenario: Agent gets SData linked collection
    Given there is an item with the following properties:
        | Name | Fourth                               |
        | UUID | 88815929-A503-4fcb-B5CC-F1BB8ECFC874 |
    When I get /items/$linked
    Then response body should contain Atom Feed
    And feed should contain 1 entries
    
  Scenario: Agent gets SData linked collection with predicate
    Given there is an item with the following properties:
        | Name | Fourth                               |
        | UUID | 88815929-A503-4fcb-B5CC-F1BB8ECFC874 |
    When I get /items/$linked(name eq 'Second')
    Then response body should contain Atom Feed
    And feed should contain 0 entries