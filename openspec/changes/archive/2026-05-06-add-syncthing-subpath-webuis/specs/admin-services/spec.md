## ADDED Requirements

### Requirement: Syncthing admin browser access MAY use shared-host subpath entrypoints
Syncthing administrative browser access SHALL remain private-first and MAY be exposed through shared-host subpath entrypoints rather than only root-host or tunnel-based access.

#### Scenario: Operator opens Syncthing admin UI for a host
- **WHEN** a host has a declared Syncthing admin browser route
- **THEN** the operator can reach the host’s Syncthing UI through the canonical admin URL for that host-specific subpath
- **AND** the access path remains compatible with existing private-origin and admin access controls
