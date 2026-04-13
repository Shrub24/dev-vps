## MODIFIED Requirements

### Requirement: Per-service exposure mode is explicit
Each routed service SHALL declare one exposure mode, with phase-1 defaults using `tailscale-upstream` or `tailscale-only`; `direct` remains available but deferred to explicit edge-local exceptions.

#### Scenario: Service exposure policy is configured
- **WHEN** a service is added to ingress configuration
- **THEN** exactly one supported exposure mode is selected and enforced

#### Scenario: Exposure mode is omitted
- **WHEN** a service route does not explicitly set exposure mode
- **THEN** the route defaults to `tailscale-upstream`

#### Scenario: Direct mode is requested in phase-1
- **WHEN** a route is configured as `direct`
- **THEN** it is treated as an explicit edge-local exception, not a normal cross-host default

### Requirement: Sensitive services remain private-origin and access-gated by default
Sensitive or administrative web services SHALL default to Cloudflare Access-gated public edge routing with private-origin upstream transport, while preserving explicit support for `tailscale-only` where required.

#### Scenario: Admin route has no public exposure override
- **WHEN** ingress policy is applied
- **THEN** the admin route uses Cloudflare Access-gated edge policy with private-origin upstream transport by default

#### Scenario: Operator opts into strict private-only admin path
- **WHEN** a service is explicitly configured as `tailscale-only`
- **THEN** no public route is rendered and access remains private-only
