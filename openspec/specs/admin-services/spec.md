# Spec: Admin Services

## Purpose

Define private administrative access contracts for hosts, including Tailscale SSH, Termix access, and break-glass recovery.
## Requirements
### Requirement: Admin access remains private and Tailscale-first
Administrative access SHALL remain private and Tailscale-first by default, while allowing explicit edge-gated web ingress with private-origin transport for approved admin routes.

#### Scenario: Admin network posture is evaluated
- **WHEN** admin service and firewall config are inspected
- **THEN** access paths are private by default, and any declared admin web routes are edge-gated and constrained to private-origin upstream transport

#### Scenario: Public ingress is enabled for non-admin services
- **WHEN** mixed exposure policy is configured
- **THEN** admin endpoints remain private-first and access-gated with private-origin transport unless explicitly changed

### Requirement: Termix is exposed through controlled service wiring
Termix SHALL run under declared service wiring and SHALL be exposed through controlled private-origin routing, independent from public Caddy app routes.

#### Scenario: Termix service stack starts
- **WHEN** admin application is enabled
- **THEN** dependent units and runtime paths are configured for Termix availability

#### Scenario: Caddy ingress route map is generated
- **WHEN** public and private service routes are composed
- **THEN** Termix/admin routes are excluded from public mappings by default

### Requirement: Declarative SSH key ownership is enforced
SSH access for administrative users SHALL be sourced from declarative key configuration.

#### Scenario: User/key configuration is rendered
- **WHEN** user modules are evaluated
- **THEN** required admin users receive declared authorized keys

### Requirement: Break-glass recovery path exists
Provider-appropriate break-glass recovery SHALL be documented and operationally available.

#### Scenario: Remote admin path fails
- **WHEN** Tailscale/SSH access is unavailable
- **THEN** documented recovery procedures can be used to regain control

