## ADDED Requirements

### Requirement: Admin export-first services SHALL define app-native backup behavior
Stateful admin services that require application-aware recovery, including Kanidm and Vaultwarden, SHALL participate in the backup architecture with export-first behavior and initial raw-state capture.

#### Scenario: Admin backup contract is reviewed for identity and password services
- **WHEN** backup behavior is inspected for Kanidm or Vaultwarden
- **THEN** each service defines or consumes export-first backup behavior
- **AND** Kanidm may satisfy that contract with its upstream automatic backup artifact while the initial backup payload still includes generated recovery artifacts and raw service state
