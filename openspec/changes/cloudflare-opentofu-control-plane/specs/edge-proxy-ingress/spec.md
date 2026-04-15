## MODIFIED Requirements

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
