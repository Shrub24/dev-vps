# edge-proxy-ingress Specification

## Purpose
TBD - created by archiving change phase1-caddy-edge-proxy. Update Purpose after archive.
## Requirements
### Requirement: Single-domain ingress supports flat subdomain routing
The ingress layer SHALL support serving services under one primary domain using flat subdomain routing for phase-1 host rollout.

#### Scenario: Route map is rendered for a host
- **WHEN** ingress routes are evaluated
- **THEN** each routed service maps to a flat subdomain under the same primary domain

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

### Requirement: Cloudflare DNS-01 certificates are automated
Ingress TLS certificates SHALL be issued using Cloudflare DNS challenge integration with host-scoped credentials.

#### Scenario: Certificate automation is enabled
- **WHEN** ingress starts with DNS challenge configuration
- **THEN** certificates are requested/renewed through Cloudflare DNS-01 without HTTP challenge dependency

### Requirement: Route ownership is modular by host and service
Ingress route declarations SHALL be composable per host and per service without hardcoding a single fixed topology.

#### Scenario: Different hosts expose different services
- **WHEN** host role composition differs between nodes
- **THEN** each host publishes only its declared route set while reusing common ingress module contracts

### Requirement: Sensitive services remain private-origin and access-gated by default
Sensitive or administrative web services SHALL default to private-origin transport with edge access controls, while preserving explicit support for `tailscale-only` where required.

#### Scenario: Admin route has no public exposure override
- **WHEN** ingress policy is applied
- **THEN** the admin route uses access-gated edge policy with private-origin upstream transport by default

#### Scenario: Operator opts into strict private-only admin path
- **WHEN** a service is explicitly configured as `tailscale-only`
- **THEN** no public route is rendered and access remains private-only

