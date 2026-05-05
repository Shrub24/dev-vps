## ADDED Requirements

### Requirement: Recoverable hosts SHALL include host-scoped state backup architecture
Fleet hosts that carry mutable service state SHALL support host-scoped declarative backup wiring as part of the recoverable baseline.

#### Scenario: Recoverability baseline is evaluated for active hosts
- **WHEN** `nixosConfigurations.do-admin-1` and `nixosConfigurations.oci-melb-1` are reviewed for operational baseline coverage
- **THEN** each host can opt into canonical host-scoped state backup wiring without introducing cross-host repository sharing by default
