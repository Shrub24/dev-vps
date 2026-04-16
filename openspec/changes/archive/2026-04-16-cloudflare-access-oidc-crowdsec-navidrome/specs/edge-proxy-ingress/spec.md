## ADDED Requirements

### Requirement: Admin routes SHALL remain Access-gated by default with explicit exceptions
Public admin-facing routes SHALL continue to require Cloudflare Access gating by default, with route-level exceptions allowed only when explicitly declared and justified.

Exception declarations consumed by this change SHALL come from canonical shared policy (`policy/web-services.nix`) and Cloudflare control-plane ownership (`cloudflare-opentofu-control-plane`) rather than ad-hoc unmanaged route policy.

#### Scenario: Standard admin route is rendered
- **WHEN** a public admin route is rendered without exception flags
- **THEN** it enforces Cloudflare Access header gate behavior
- **AND** it retains existing admin-safe ingress defaults

#### Scenario: Route-level exception is declared
- **WHEN** a route is explicitly marked as exception in this change scope
- **THEN** the exception is visible in route declarations and contract checks
- **AND** exception intent is documented in change artifacts

#### Scenario: Pocket ID route is declared as upstream-IdP exception
- **WHEN** Pocket ID route is rendered for shared IdP hosting
- **THEN** it is explicitly declared as a direct orange-cloud exception and is not Access-gated
- **AND** this exception is documented as required to avoid Access→IdP loop behavior

### Requirement: Cloudflare Access SHALL use Pocket ID as upstream IdP
Cloudflare Access configuration for admin browser routes SHALL use Pocket ID generic OIDC as upstream identity provider in this change scope.

#### Scenario: Access IdP switch is evaluated
- **WHEN** Cloudflare Access resources/inputs are evaluated
- **THEN** upstream IdP endpoints and client credentials resolve to Pocket ID values
- **AND** legacy Google OAuth upstream assumptions are removed from this change scope

### Requirement: Music route SHALL reflect orange-cloud exposure posture with caching disabled
The music/Navidrome ingress posture SHALL be modeled as orange-cloud while ensuring CDN/caching is disabled via control-plane policy.

#### Scenario: Music route policy is evaluated
- **WHEN** route posture for music/Navidrome is reviewed in this change
- **THEN** artifacts and route checks treat music as an orange-cloud DNS exposure class
- **AND** control-plane policy disables CDN/caching for the music endpoint

### Requirement: Bypassed route classes SHALL stay explicit and minimal
Ingress policy changes that preserve bypassed/non-Access traffic classes SHALL keep exceptions explicit and constrained in canonical policy.

#### Scenario: Exposed/bypassed route classes exist
- **WHEN** route set includes traffic classes outside normal Access-gated browser flow
- **THEN** exception routes are explicitly declared in canonical policy and contract checks

### Requirement: Exposed routes in this pivot SHALL use orange-cloud posture by default
For routes in scope of this pivot, Cloudflare DNS/proxy posture SHALL be modeled as orange-cloud by default unless an explicit exception is documented.

#### Scenario: In-scope admin route posture is evaluated
- **WHEN** route policy for this pivot is rendered
- **THEN** route exposure class is orange-cloud by default
- **AND** any non-default posture is explicitly declared with rationale in artifacts

### Requirement: Traffic blocking SHALL rely on Cloudflare edge controls in this rollout
Traffic filtering and firewalling for exposed traffic in this rollout SHALL be handled by Cloudflare control-plane policies rather than host-layer CrowdSec.

#### Scenario: Security baseline for exposed traffic is reviewed
- **WHEN** rollout security controls are evaluated
- **THEN** Cloudflare firewall/WAF/traffic policies are the primary blocking layer
- **AND** CrowdSec host-layer controls are not required in this change scope
