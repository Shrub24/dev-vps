## ADDED Requirements

### Requirement: Karakeep route SHALL be exposed through canonical gated edge policy
Karakeep SHALL be exposed as a declared web service route through canonical `do-admin-1` edge-ingress policy using `tailscale-upstream` transport to private origin on `oci-melb-1`.

#### Scenario: Karakeep route is declared in canonical policy
- **WHEN** policy maps are resolved for `do-admin-1`
- **THEN** a `karakeep` route is rendered with `tailscale-upstream` origin transport to `oci-melb-1`
- **AND** route ownership remains single-sourced in `policy/web-services.nix`

### Requirement: Karakeep public route SHALL rely on app-native auth and AOP
The Karakeep route SHALL NOT require Cloudflare Access gating, and SHALL require Authenticated Origin Pulls under host-level route policy while relying on app-native auth for browser and mobile/API clients.

#### Scenario: Karakeep route policy is rendered
- **WHEN** edge route attributes are generated from canonical web-services policy
- **THEN** `cloudflareAccessRequired` is disabled for `karakeep`
- **AND** authenticated origin pulls are required for the Karakeep host/route set
