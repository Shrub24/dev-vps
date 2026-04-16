## ADDED Requirements

### Requirement: Fleet package baseline defaults to unstable
Fleet host outputs SHALL consume the primary repository package baseline from `nixos-unstable` unless an explicit documented exception is introduced.

#### Scenario: Active host outputs are evaluated
- **WHEN** `nixosConfigurations.oci-melb-1` and `nixosConfigurations.do-admin-1` are built from the flake
- **THEN** both host outputs resolve packages from the primary unstable baseline input
