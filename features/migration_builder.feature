Feature: Building a migration
  Given I want to be able to build migrations
  As a CI server
  Then I need to be able to pass the relevant information into the command line

  Scenario: Exit status
    When I run `vara-generate-migration --product-name redis --to-version '0.0.0.5' --output migration.yml`
    Then the exit status should be 0

  Scenario: Helpful output upon successful migration build
    When I run `vara-generate-migration --product-name redis --to-version '0.0.0.5' --output migration.yml`
    Then the output should match /migration written to (.)+migration.yml/

  Scenario: Checking the file for output
    When I run `vara-generate-migration --product-name redis --to-version '0.0.0.5' --output migration.yml`
    Then the file "migration.yml" should contain "product: redis"
    And the file "migration.yml" should contain "to_version: 0.0.0.5"
    And the file "migration.yml" should contain "product_version: 0.0.0.4"