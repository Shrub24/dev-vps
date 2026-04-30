## ADDED Requirements

### Requirement: Tagr route SHALL be exposed through canonical gated edge policy
Tagr SHALL be exposed as a declared web service route through canonical `do-admin-1` edge-ingress policy using `tailscale-upstream` transport to private origin.

#### Scenario: Tagr route is declared in canonical policy
- **WHEN** policy maps are resolved for `do-admin-1`
- **THEN** a `tagr` route is rendered with `tailscale-upstream` origin transport to `oci-melb-1`

### Requirement: Tagr public route SHALL enforce Cloudflare Access and AOP
The Tagr route SHALL require Cloudflare Access gating and SHALL require Authenticated Origin Pulls under host-level route policy.

#### Scenario: Tagr route policy is rendered
- **WHEN** edge route attributes are generated from canonical web-services policy
- **THEN** `cloudflareAccessRequired` is enforced for `tagr`
- **AND** authenticated origin pulls are required for the Tagr host/route set
