## MODIFIED Requirements

### Requirement: Baseline access is private-first
Management and service access SHALL be private and Tailscale-first by default, with explicit policy-controlled exceptions for Phase-1 edge ingress.

#### Scenario: Baseline network posture is checked
- **WHEN** host and service network settings are evaluated
- **THEN** public exposure is absent unless explicitly introduced by a separate change

#### Scenario: Hybrid ingress exception is introduced
- **WHEN** a route is explicitly configured for public edge exposure
- **THEN** the public surface is limited to declared Caddy ingress routes while upstream transport remains Tailscale-encrypted by default

#### Scenario: Constant-availability exception is introduced
- **WHEN** a route is explicitly configured as `direct`
- **THEN** it is treated as an explicit exception to the Tailscale-encrypted default and is constrained to declared exposure policy

### Requirement: Firewall trust boundaries are explicit
Firewall policy SHALL enforce explicit trust boundaries for allowed interfaces and ports, including constrained ingress exposure for declared edge routes.

#### Scenario: Firewall config is rendered
- **WHEN** networking/firewall modules are evaluated
- **THEN** only declared interfaces/ports are trusted/opened

#### Scenario: Edge host policy is applied
- **WHEN** an edge host is configured for public ingress
- **THEN** only ingress-required ports are opened and private-service ports remain non-public
