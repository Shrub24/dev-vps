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
Sensitive or administrative web services SHALL default to Cloudflare Access-gated public edge routing with private-origin upstream transport, while preserving explicit support for `tailscale-only` where required.

#### Scenario: Admin route has no public exposure override
- **WHEN** ingress policy is applied
- **THEN** the admin route uses Cloudflare Access-gated edge policy with private-origin upstream transport by default

#### Scenario: Operator opts into strict private-only admin path
- **WHEN** a service is explicitly configured as `tailscale-only`
- **THEN** no public route is rendered and access remains private-only

### Requirement: Edge DNS publication SHALL consume canonical policy exports
Cloudflare DNS publication for edge routes SHALL consume generated policy exports from the canonical web-services map.

#### Scenario: Service subdomain is declared
- **WHEN** a service has a `subdomain` in canonical policy
- **THEN** OpenTofu plans a corresponding DNS record under the configured zone

#### Scenario: Service proxy posture is declared
- **WHEN** a service defines `cloudflare.proxied`
- **THEN** OpenTofu applies that proxied setting to the DNS record

### Requirement: Edge policy inputs SHALL come from canonical web-services policy
Ingress policy defaults and explicit exceptions used by edge-proxy-ingress SHALL be sourced from the canonical policy map at `policy/web-services.nix`.

#### Scenario: Default policy is consumed
- **WHEN** a route has no explicit override
- **THEN** the declared global policy from canonical map is applied

#### Scenario: Host/route override is consumed
- **WHEN** a host or route is explicitly declared as an exception
- **THEN** edge-proxy-ingress consumes that exception and preserves explicit behavior in rendered route policy

### Requirement: OpenTofu input SHALL be generated from canonical web-services policy
Cloudflare OpenTofu inputs SHALL be generated from `policy/web-services.nix` through a JSON export artifact to avoid duplicated policy declarations.

#### Scenario: OpenTofu consumes policy for Cloudflare resources
- **WHEN** OpenTofu plans/applies Cloudflare DNS/Access resources
- **THEN** it reads generated JSON exported from canonical web-services policy

### Requirement: Music route class SHALL support grey-cloud posture declaration
The control-plane model SHALL represent music/Navidrome routes as a distinct grey-cloud class so ingress policy does not assume Cloudflare-proxied controls.

#### Scenario: Music policy is evaluated
- **WHEN** music/Navidrome route policy is generated
- **THEN** the route class is marked as grey-cloud in control-plane declarations

