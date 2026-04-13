## MODIFIED Requirements

### Requirement: Baseline access is private-first
Management and service access SHALL be private and Tailscale-first by default, with a designated public edge bastion for explicitly declared web routes.

#### Scenario: Baseline network posture is checked
- **WHEN** host and service network settings are evaluated
- **THEN** non-edge origin services remain private unless explicitly introduced by a separate change

#### Scenario: Hybrid ingress exception is introduced
- **WHEN** a route is explicitly configured for public edge exposure
- **THEN** the public surface is limited to declared Cloudflare/Caddy ingress routes while upstream transport remains private-origin and Tailscale-encrypted by default for cross-host services

#### Scenario: Constant-availability exception is introduced
- **WHEN** a route is explicitly configured as `direct`
- **THEN** it is treated as an explicit, edge-local-only localhost exception to the Tailscale-upstream default and is constrained to declared exposure policy
