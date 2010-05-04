Feature: Display error payloads

  Background:
    Given there are following items:
      | First     |
      | Second    |
      | Third     |

  Scenario: Request correct sdata url
    When I get /sdata/example/crmErp/-/items
    Then response body should contain Atom Feed
    And feed should contain element "title" with value "Items"
    And feed should contain 3 entries

  Scenario: Request address that results in uncustomized exception
    When I get /sdata/example/crmErp/-/item/asdf
    Then response should be a standalone "ApplicationDiagnosis" diagnosis with status "500"
    
  Scenario: Request incorrect resource kind
    When I get /sdata/example/crmErp/-/item
    Then response should be a standalone "ResourceKindNotFound" diagnosis with status "404"
    
  Scenario: Request unsupported intermediate URL of resource kinds
    When I get /sdata/example/crmErp/-
    Then response should be a standalone "ApplicationDiagnosis" diagnosis with status "501"
    
  Scenario: Request incorrect contract
    When I get /sdata/example/crmErp/somecontract
    Then response should be a standalone "ContractNotFound" diagnosis with status "404"
    
  Scenario: Request unsupported intermediate URL of contracts
    When I get /sdata/example/crmErp
    Then response should be a standalone "ApplicationDiagnosis" diagnosis with status "501"
    
  Scenario: Request incorrect dataset
    When I get /sdata/example/somedataset
    Then response should be a standalone "DatasetNotFound" diagnosis with status "404"
    
  Scenario: Request unsupported intermediate URL of datasets
    When I get /sdata/example
    Then response should be a standalone "ApplicationDiagnosis" diagnosis with status "501"
    
  Scenario: Request incorrect application
    When I get /sdata/someapplication
    Then response should be a standalone "ApplicationNotFound" diagnosis with status "404"