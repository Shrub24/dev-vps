## MODIFIED Requirements

### Requirement: Admin web access is edge-gated with private-origin transport by default
Administrative web access SHALL default to edge access controls with private-origin transport, while preserving Tailscale-only mode for routes that must remain non-public.

#### Scenario: Admin network posture is evaluated
- **WHEN** admin service and firewall config are inspected
- **THEN** admin routes are access-gated at the edge and constrained to private-origin upstream transport

#### Scenario: Public ingress is enabled for non-admin services
- **WHEN** mixed exposure policy is configured
- **THEN** admin endpoints remain access-gated with private-origin transport unless explicitly changed

### Requirement: Termix is exposed through controlled service wiring
Termix SHALL run under declared service wiring and SHALL be exposed through controlled private-origin routing, independent from public Caddy app routes.

#### Scenario: Termix service stack starts
- **WHEN** admin application is enabled
- **THEN** dependent units and runtime paths are configured for Termix availability

#### Scenario: Caddy ingress route map is generated
- **WHEN** public and private service routes are composed
- **THEN** Termix/admin routes are excluded from public mappings by default
