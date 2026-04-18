## ADDED Requirements

### Requirement: SoulSync route SHALL be exposed through canonical gated edge policy
SoulSync SHALL be exposed as a declared web service route through the canonical `do-admin-1` edge-ingress policy path, using `tailscale-upstream` transport to private origin.

#### Scenario: SoulSync route is declared in canonical policy
- **WHEN** policy maps are resolved for `do-admin-1`
- **THEN** a `soulsync` route is rendered with `tailscale-upstream` origin transport

### Requirement: SoulSync public route SHALL enforce Cloudflare Access and AOP
The SoulSync route SHALL require Cloudflare Access gating and SHALL require Authenticated Origin Pulls (AOP) under the host-level route policy model.

#### Scenario: SoulSync route policy is rendered
- **WHEN** edge route attributes are generated from canonical web-services policy
- **THEN** `cloudflareAccessRequired` is enforced for SoulSync
- **AND** authenticated origin pulls are required for the host/route set

### Requirement: SoulSync day-1 public posture SHALL be control-plane first
SoulSync public exposure SHALL prioritize control-plane/UI use, with best-effort suppression of playback affordances when practical, and SHALL document residual playback behavior if suppression is incomplete.

#### Scenario: Playback suppression capability is limited upstream
- **WHEN** SoulSync lacks a clean supported full player-disable switch
- **THEN** rollout remains permitted under Access-gated/AOP-protected route policy
- **AND** residual playback affordances are documented as an operational limitation
