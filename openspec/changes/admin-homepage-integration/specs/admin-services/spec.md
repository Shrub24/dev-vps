## MODIFIED Requirements

### Requirement: Admin baseline SHALL provide central visibility without host log replication
This stage SHALL provide centralized operational visibility using Homepage as the primary operator landing page, with Cockpit, Beszel hub, and Gatus surfaced as first-class visibility targets, while deferring cross-host L1 log replication to a later dedicated logging change.

#### Scenario: Homepage is the central admin visibility surface
- **WHEN** the admin baseline is deployed
- **THEN** Homepage is enabled as the operator dashboard surface
- **AND** it provides actionable links and/or widgets for Cockpit, Beszel hub, and Gatus
- **AND** no requirement is introduced that hosts must run journald remote/upload replication in this stage
