## MODIFIED Requirements

### Requirement: Single-domain ingress supports flat subdomain routing
The ingress layer SHALL support serving services under one primary domain using flat subdomain routing for phase-1 host rollout, with the primary domain value sourced from canonical policy/config rather than duplicated literals in multiple modules.

#### Scenario: Route map is rendered for a host
- **WHEN** ingress routes are evaluated
- **THEN** each routed service maps to a flat subdomain under the same primary domain
- **AND** the primary domain is resolved from canonical policy/config inputs

### Requirement: Edge policy inputs SHALL come from canonical web-services policy
Ingress policy defaults and explicit exceptions used by edge-proxy-ingress SHALL be sourced from the canonical policy map at `policy/web-services.nix`, including authoritative subdomain/path declarations.

#### Scenario: Default policy is consumed
- **WHEN** a route has no explicit override
- **THEN** the declared global policy from canonical map is applied

#### Scenario: Host/route override is consumed
- **WHEN** a host or route is explicitly declared as an exception
- **THEN** edge-proxy-ingress consumes that exception and preserves explicit behavior in rendered route policy

#### Scenario: Route path is configured once
- **WHEN** route path metadata is required for edge rendering
- **THEN** path values come from canonical policy entries
- **AND** path literals are not redefined in separate edge module constants

### Requirement: OpenTofu input SHALL be generated from canonical web-services policy
Cloudflare OpenTofu inputs SHALL be generated from `policy/web-services.nix` through a JSON export artifact to avoid duplicated policy declarations, including canonical subdomain values.

#### Scenario: OpenTofu consumes policy for Cloudflare resources
- **WHEN** OpenTofu plans/applies Cloudflare DNS/Access resources
- **THEN** it reads generated JSON exported from canonical web-services policy
