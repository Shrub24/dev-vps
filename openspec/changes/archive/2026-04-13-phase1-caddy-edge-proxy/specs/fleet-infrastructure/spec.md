## MODIFIED Requirements

### Requirement: Access model is private-first
Management and service access SHALL be Tailscale-first and SHALL not include public exposure in baseline configuration.

#### Scenario: Network posture is validated
- **WHEN** network and service configs are inspected
- **THEN** baseline access remains private and public exposure is absent by default

#### Scenario: Phase-1 edge ingress is composed
- **WHEN** a host is designated to publish selected routes
- **THEN** only explicitly declared routes are exposed and private transport boundaries are preserved for upstream services

### Requirement: Host composition is host-centric and modular
The repository SHALL organize host identity separately from reusable modules so hosts can add ingress behavior without structural rewrites.

#### Scenario: A host is composed from shared modules
- **WHEN** a host configuration is declared in `hosts/<host>/default.nix`
- **THEN** it composes reusable modules rather than embedding provider/service logic inline

#### Scenario: Edge role is assigned to one host
- **WHEN** only one host is configured as ingress edge
- **THEN** other hosts can remain private-origin nodes with shared module composition patterns
